mkdir -p build

# Fix vendored fmt in SEACAS/Ioss: format.h defines fmt::detail::allocator<T>
# using unqualified malloc/free, but <cstdlib> is not visible at the point of
# the template definition. Older toolchains pulled it in transitively; the
# current Clang + macOS SDK do not, and strict two-phase name lookup then
# rejects the unqualified names ("'free' should be declared prior to the call
# site"). Prepend <cstdlib> so malloc/free are declared before the template.
find $SRC_DIR/packages/seacas -path '*private_copy_fmt/fmt/format.h' | while read -r fmt_hdr; do
  if ! grep -q '#include <cstdlib>' "$fmt_hdr"; then
    printf '%s\n' '#include <cstdlib>' | cat - "$fmt_hdr" > "$fmt_hdr.new"
    mv "$fmt_hdr.new" "$fmt_hdr"
  fi
done

# Build binder, the Clang-based generator PyTrilinos2 uses to write its pybind11
# bindings. It is not packaged on conda-forge, so build it here against the host
# LLVM/Clang and install it under $SRC_DIR: it only runs during this build and
# never lands in $PREFIX, so no output ships it.
BINDER_PREFIX=$SRC_DIR/_binder
BINDER_LDFLAGS="${LDFLAGS}"
if [[ "${target_platform}" == osx-* ]]; then
    # binder's CMake skips libLLVM on macOS, assuming libclang-cpp re-exports
    # it; conda-forge's libclang-cpp does not, so link it explicitly.
    BINDER_LDFLAGS="${BINDER_LDFLAGS} -lLLVM"
fi
cmake -G Ninja -S $SRC_DIR/binder -B $SRC_DIR/binder-build \
  ${CMAKE_ARGS} \
  -D CMAKE_BUILD_TYPE:STRING=Release \
  -D CMAKE_INSTALL_PREFIX:PATH=$BINDER_PREFIX \
  -D CMAKE_EXE_LINKER_FLAGS="${BINDER_LDFLAGS}" \
  -D LLVM_DIR:PATH=$PREFIX/lib/cmake/llvm \
  -D Clang_DIR:PATH=$PREFIX/lib/cmake/clang \
  -D BINDER_ENABLE_TEST:BOOL=OFF
cmake --build $SRC_DIR/binder-build --target install
$BINDER_PREFIX/bin/binder --version

# binder parses the Trilinos headers with the host Clang, not the compiler that
# builds Trilinos, so point it at the Clang resource headers, the target system
# headers and the C++ standard library explicitly.
BINDER_FLAGS="-resource-dir=$(echo $PREFIX/lib/clang/*)"
if [[ "${target_platform}" == osx-* ]]; then
    # Use the libc++ headers that ship with the host Clang (the SDK's are too
    # old for C++20, and the build compiler's may be newer than Clang supports).
    BINDER_FLAGS="${BINDER_FLAGS};-isysroot;${CONDA_BUILD_SYSROOT:-${SDKROOT}};-nostdinc++;-isystem;${PREFIX}/include/c++/v1"
    BINDER_FLAGS="${BINDER_FLAGS};-D_LIBCPP_DISABLE_AVAILABILITY"
else
    # libstdc++ comes from the conda GCC toolchain (via the GCC_TOOLCHAIN option
    # below); omp.h lives in GCC's private include dir, so search it last.
    BINDER_FLAGS="${BINDER_FLAGS};--target=${HOST};--sysroot=${CONDA_BUILD_SYSROOT}"
    BINDER_FLAGS="${BINDER_FLAGS};-idirafter;$(dirname $(${CXX} -print-file-name=include/omp.h))"
    BINDER_GCC_TOOLCHAIN_ARG="-DPyTrilinos2_BINDER_GCC_TOOLCHAIN:PATH=${BUILD_PREFIX}"
fi

cd build

export CMAKE_GENERATOR="Ninja"

if [[ "${target_platform}" == osx-* ]]; then
    # Sacado specializes std::is_same / std::is_same_v for its Kokkos layout
    # types (Kokkos_LayoutContiguous.hpp, Kokkos_LayoutNatural.hpp, ...). The
    # current libc++ marks those std entities with [[clang::no_specializations]],
    # which turns this long-standing specialization into a hard error under the
    # -Winvalid-specialization group (DefaultError). libstdc++ (linux) has no
    # such marker, so only osx is affected. Suppress the group to restore the
    # previous behavior; the specialization is intentional and semantically fine.
    export CXXFLAGS="${CXXFLAGS} -stdlib=libc++ -D_LIBCPP_DISABLE_AVAILABILITY -Wno-invalid-specialization"
fi

export MPI_FLAGS="--allow-run-as-root"

if [ $(uname) == Linux ]; then
    export MPI_FLAGS="$MPI_FLAGS;-mca;plm;isolated"
fi

cmake -G Ninja \
  -D CMAKE_BUILD_TYPE:STRING=RELEASE \
  -D CMAKE_INSTALL_PREFIX:PATH=$PREFIX \
  -D CMAKE_PREFIX_PATH:PATH=$PREFIX \
  -D BUILD_SHARED_LIBS:BOOL=ON \
  -D TPL_ENABLE_MPI:BOOL=ON \
  -D MPI_BASE_DIR:PATH=$PREFIX \
  -D MPI_EXEC:FILEPATH=$PREFIX/bin/mpiexec \
  -D Python3_EXECUTABLE:FILEPATH=$PYTHON \
  -D CMAKE_C_FLAGS="-Wno-implicit-function-declaration" \
  -D TPL_ENABLE_Kokkos:BOOL=ON \
  -D TPL_ENABLE_KokkosKernels:BOOL=ON \
  -D Kokkos_DIR:PATH="${PREFIX}/lib/cmake/Kokkos" \
  -D KokkosKernels_DIR:PATH="${PREFIX}/lib/cmake/KokkosKernels" \
  -D Trilinos_ENABLE_OpenMP:BOOL=ON \
  -D Trilinos_ENABLE_Fortran:BOOL=OFF \
  -D Trilinos_ENABLE_ALL_PACKAGES:BOOL=OFF \
  -D Trilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \
  -D Trilinos_ENABLE_TESTS:BOOL=OFF \
  -D Trilinos_ENABLE_EXAMPLES:BOOL=OFF \
  -D Trilinos_ENABLE_Teuchos:BOOL=ON \
  -D Trilinos_ENABLE_RTOp:BOOL=ON \
  -D Trilinos_ENABLE_Sacado:BOOL=ON \
  -D Trilinos_ENABLE_MiniTensor:BOOL=ON \
  -D Trilinos_ENABLE_Zoltan:BOOL=ON \
  -D Trilinos_ENABLE_Shards:BOOL=ON \
  -D Trilinos_ENABLE_Tpetra:BOOL=ON \
  -D Trilinos_ENABLE_Thyra:BOOL=ON \
  -D Trilinos_ENABLE_Xpetra:BOOL=ON \
  -D Trilinos_ENABLE_Galeri:BOOL=ON \
  -D TPL_ENABLE_UMFPACK:BOOL=ON \
  -D UMFPACK_LIBRARY_DIRS:PATH="${PREFIX}/lib/suitesparse" \
  -D UMFPACK_INCLUDE_DIRS:PATH="${PREFIX}/include/suitesparse" \
  -D Trilinos_ENABLE_Pamgen:BOOL=ON \
  -D Trilinos_ENABLE_Zoltan2:BOOL=ON \
  -D Trilinos_ENABLE_Belos:BOOL=ON \
  -D Trilinos_ENABLE_ShyLU:BOOL=ON \
  -D Trilinos_ENABLE_Amesos2:BOOL=ON \
  -D Trilinos_ENABLE_SEACAS:BOOL=ON \
  -D TPL_ENABLE_HDF5:BOOL=ON \
  -D TPL_HDF5_INCLUDE_DIRS:PATH="${PREFIX}/include" \
  -D TPL_HDF5_LIBRARY_DIRS:PATH="${PREFIX}/lib" \
  -D TPL_HDF5_LIBRARIES:STRING="${PREFIX}/lib/libhdf5_hl${SHLIB_EXT};${PREFIX}/lib/libhdf5${SHLIB_EXT};${PREFIX}/lib/libz${SHLIB_EXT}" \
  -D TPL_Netcdf_INCLUDE_DIRS:PATH="${PREFIX}/include" \
  -D TPL_Netcdf_LIBRARIES:STRING="${PREFIX}/lib/libnetcdf${SHLIB_EXT}" \
  -D TPL_Matio_INCLUDE_DIRS:PATH="${PREFIX}/include" \
  -D TPL_Matio_LIBRARIES:STRING="${PREFIX}/lib/libmatio${SHLIB_EXT}" \
  -D TPL_Boost_INCLUDE_DIRS:PATH="${PREFIX}/include" \
  -D Trilinos_ENABLE_Anasazi:BOOL=ON \
  -D Trilinos_ENABLE_Ifpack2:BOOL=ON \
  -D Ifpack2_ENABLE_TESTS:BOOL=OFF \
  -D Trilinos_ENABLE_Stratimikos:BOOL=ON \
  -D Trilinos_ENABLE_Teko:BOOL=ON \
  -D Trilinos_ENABLE_STK:BOOL=OFF \
  -D Trilinos_ENABLE_Phalanx:BOOL=ON \
  -D Trilinos_ENABLE_NOX:BOOL=ON \
  -D NOX_ENABLE_LOCA:BOOL=ON \
  -D Trilinos_ENABLE_MueLu:BOOL=ON \
  -D Trilinos_ENABLE_Stokhos:BOOL=ON \
  -D Trilinos_ENABLE_ROL:BOOL=ON \
  -D Trilinos_ENABLE_Piro:BOOL=ON \
  -D Trilinos_ENABLE_TrilinosCouplings:BOOL=ON \
  -D Teuchos_ENABLE_COMPLEX:BOOL=ON \
  -D Trilinos_ENABLE_COMPLEX_DOUBLE:BOOL=ON \
  -D Trilinos_ENABLE_DEPRECATED_CODE_WARNINGS:BOOL=OFF \
  -D Trilinos_ENABLE_PyTrilinos2:BOOL=ON \
  -D PyTrilinos2_INSTALL_DIR:PATH=$SP_DIR/PyTrilinos2 \
  -D BINDER_EXECUTABLE:FILEPATH=$BINDER_PREFIX/bin/binder \
  -D PyTrilinos2_BINDER_FLAGS="${BINDER_FLAGS}" \
  ${BINDER_GCC_TOOLCHAIN_ARG} \
  -D LLVM_DIR:PATH=$PREFIX/lib/cmake/llvm \
  $SRC_DIR

JOBS=$(( CPU_COUNT > 1 ? CPU_COUNT - 1 : 1))
ninja -j "$JOBS"
ninja install
