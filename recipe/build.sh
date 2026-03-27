mkdir -p build

# Fix Python version detection for Python >= 3.10: sys.version[:3] returns "3.1"
# instead of "3.10", "3.12", etc. Replace with sys.version_info-based extraction.
# This is done via sed in addition to the patch file for reliability.
find $SRC_DIR/packages/PyTrilinos $SRC_DIR/packages/epetraext \
  \( -name '*.cmake' -o -name 'CMakeLists.txt' \) -exec \
  sed -i.bak "s|sys.version\[:3\]|'%d.%d' % (sys.version_info.major, sys.version_info.minor)|g" {} +
find $SRC_DIR/packages/PyTrilinos $SRC_DIR/packages/epetraext \
  \( -name '*.cmake.bak' -o -name 'CMakeLists.txt.bak' \) -delete

# Fix SWIG 4.3+ compatibility: SWIG_Python_AppendOutput now takes 3 args.
# PyTrilinos typemaps use the old 2-arg signature. Add the third arg (0 = not void).
find $SRC_DIR/packages/PyTrilinos/src -name '*.i' -exec \
  sed -i.bak 's/SWIG_Python_AppendOutput(\(.*\));/SWIG_Python_AppendOutput(\1, 0);/g' {} +
find $SRC_DIR/packages/PyTrilinos/src -name '*.i.bak' -delete

# Fix PyTrilinos_NumPy symbol visibility: NumPy 2.x defaults NPY_API_SYMBOL_ATTRIBUTE
# to NPY_VISIBILITY_HIDDEN, which hides the PyArray_API symbol (renamed to
# PyTrilinos_NumPy via PY_ARRAY_UNIQUE_SYMBOL) inside libpytrilinos.so. The SWIG
# extension modules link against libpytrilinos.so and need this symbol exported.
# Override NPY_API_SYMBOL_ATTRIBUTE before numpy headers are included.
sed -i.bak 's/^#define PY_ARRAY_UNIQUE_SYMBOL PyTrilinos_NumPy/#define NPY_API_SYMBOL_ATTRIBUTE __attribute__((visibility("default")))\n#define PY_ARRAY_UNIQUE_SYMBOL PyTrilinos_NumPy/' \
  $SRC_DIR/packages/PyTrilinos/src/numpy_include.hpp
rm -f $SRC_DIR/packages/PyTrilinos/src/numpy_include.hpp.bak

cd build

export CMAKE_GENERATOR="Ninja"

if [[ "${target_platform}" == osx-* ]]; then
    export CXXFLAGS="${CXXFLAGS} -stdlib=libc++ -D_LIBCPP_DISABLE_AVAILABILITY"
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
  -D PYTHON_EXECUTABLE:FILEPATH=$PYTHON \
  -D Python3_EXECUTABLE:FILEPATH=$PYTHON \
  -D PyTrilinos_INSTALL_DIR:PATH=$PREFIX/lib/python${PY_VER}/site-packages/PyTrilinos \
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
  -D Trilinos_ENABLE_Epetra:BOOL=ON \
  -D Trilinos_ENABLE_Zoltan:BOOL=ON \
  -D Trilinos_ENABLE_Shards:BOOL=ON \
  -D Trilinos_ENABLE_GlobiPack:BOOL=ON \
  -D Trilinos_ENABLE_Triutils:BOOL=ON \
  -D Trilinos_ENABLE_Tpetra:BOOL=ON \
  -D Trilinos_ENABLE_EpetraExt:BOOL=ON \
  -D Trilinos_ENABLE_Thyra:BOOL=ON \
  -D Trilinos_ENABLE_Xpetra:BOOL=ON \
  -D Trilinos_ENABLE_Isorropia:BOOL=ON \
  -D Trilinos_ENABLE_Pliris:BOOL=ON \
  -D Trilinos_ENABLE_AztecOO:BOOL=ON \
  -D Trilinos_ENABLE_Galeri:BOOL=ON \
  -D Trilinos_ENABLE_Amesos:BOOL=ON \
  -D TPL_ENABLE_UMFPACK:BOOL=ON \
  -D UMFPACK_LIBRARY_DIRS:PATH="${PREFIX}/lib/suitesparse" \
  -D UMFPACK_INCLUDE_DIRS:PATH="${PREFIX}/include/suitesparse" \
  -D Trilinos_ENABLE_Pamgen:BOOL=ON \
  -D Trilinos_ENABLE_Zoltan2:BOOL=ON \
  -D Trilinos_ENABLE_Ifpack:BOOL=ON \
  -D Trilinos_ENABLE_ML:BOOL=ON \
  -D Trilinos_ENABLE_Belos:BOOL=ON \
  -D Trilinos_ENABLE_ShyLU:BOOL=ON \
  -D Trilinos_ENABLE_Amesos2:BOOL=ON \
  -D Trilinos_ENABLE_SEACAS:BOOL=ON \
  -D TPL_ENABLE_HDF5:BOOL=ON \
  -D Trilinos_ENABLE_Anasazi:BOOL=ON \
  -D Trilinos_ENABLE_Ifpack2:BOOL=ON \
  -D Ifpack2_ENABLE_TESTS:BOOL=OFF \
  -D Trilinos_ENABLE_Stratimikos:BOOL=ON \
  -D Trilinos_ENABLE_Teko:BOOL=ON \
  -D Trilinos_ENABLE_Intrepid:BOOL=ON \
  -D Trilinos_ENABLE_STK:BOOL=OFF \
  -D Trilinos_ENABLE_Phalanx:BOOL=ON \
  -D Trilinos_ENABLE_NOX:BOOL=ON \
  -D NOX_ENABLE_LOCA:BOOL=ON \
  -D Trilinos_ENABLE_MueLu:BOOL=ON \
  -D Trilinos_ENABLE_Rythmos:BOOL=ON \
  -D Trilinos_ENABLE_Stokhos:BOOL=ON \
  -D Trilinos_ENABLE_ROL:BOOL=ON \
  -D Trilinos_ENABLE_Piro:BOOL=ON \
  -D Trilinos_ENABLE_TrilinosCouplings:BOOL=ON \
  -D Teuchos_ENABLE_COMPLEX:BOOL=ON \
  -D Trilinos_ENABLE_COMPLEX_DOUBLE:BOOL=ON \
  -D Trilinos_ENABLE_PyTrilinos:BOOL=ON \
  -D Teuchos_ENABLE_PYTHON=ON \
  -D Trilinos_ENABLE_DEPRECATED_CODE_WARNINGS:BOOL=OFF \
  -D TPL_ENABLE_MPI4PY:BOOL=ON \
  -D PyTrilinos_ENABLE_Teuchos=ON \
  -D PyTrilinos_ENABLE_Tpetra=ON \
  -D PyTrilinos_ENABLE_Epetra=ON \
  -D PyTrilinos_ENABLE_Triutils=ON \
  -D PyTrilinos_ENABLE_EpetraExt=ON \
  -D PyTrilinos_ENABLE_Isorropia=ON \
  -D PyTrilinos_ENABLE_Pliris=ON \
  -D PyTrilinos_ENABLE_AztecOO=ON \
  -D PyTrilinos_ENABLE_Galeri=ON \
  -D PyTrilinos_ENABLE_Amesos=ON \
  -D PyTrilinos_ENABLE_Ifpack=ON \
  -D PyTrilinos_ENABLE_Anasazi=ON \
  -D PyTrilinos_ENABLE_ML=ON \
  -D PyTrilinos_ENABLE_NOX=ON \
  $SRC_DIR

ninja -j $CPU_COUNT
ninja install


