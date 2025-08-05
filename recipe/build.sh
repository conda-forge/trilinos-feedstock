mkdir -p build
cd build

export CMAKE_GENERATOR="Ninja"

if [ $(uname) == Darwin ]; then
    export CXXFLAGS="$CXXFLAGS -stdlib=libc++"
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
  -D CMAKE_C_FLAGS="-Wno-implicit-function-declaration" \
  -D TPL_ENABLE_Kokkos:BOOL=ON \
  -D TPL_ENABLE_KokkosKernels:BOOL=ON \
  -D Kokkos_DIR:PATH="${PREFIX}/lib/cmake/Kokkos" \
  -D KokkosKernels_DIR:PATH="${PREFIX}/lib/cmake/KokkosKernels" \
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
  -D Trilinos_ENABLE_Domi:BOOL=ON \
  -D Trilinos_ENABLE_Thyra:BOOL=ON \
  -D Trilinos_ENABLE_Xpetra:BOOL=ON \
  -D Trilinos_ENABLE_Isorropia:BOOL=ON \
  -D Trilinos_ENABLE_Pliris:BOOL=ON \
  -D Trilinos_ENABLE_AztecOO:BOOL=ON \
  -D Trilinos_ENABLE_Galeri:BOOL=ON \
  -D Trilinos_ENABLE_Amesos:BOOL=ON \
  -D TPL_ENABLE_UMFPACK:BOOL=ON \
  -D Trilinos_ENABLE_Pamgen:BOOL=ON \
  -D Trilinos_ENABLE_Zoltan2:BOOL=ON \
  -D Trilinos_ENABLE_Ifpack:BOOL=ON \
  -D Trilinos_ENABLE_ML:BOOL=ON \
  -D Trilinos_ENABLE_Belos:BOOL=ON \
  -D Trilinos_ENABLE_ShyLU:BOOL=ON \
  -D Trilinos_ENABLE_Amesos2:BOOL=ON \
  -D Trilinos_ENABLE_SEACAS:BOOL=ON \
  -D TPL_ENABLE_HDF5:BOOL=ON \
  -D Trilinos_ENABLE_Komplex:BOOL=ON \
  -D Trilinos_ENABLE_Anasazi:BOOL=ON \
  -D Trilinos_ENABLE_Ifpack2:BOOL=ON \
  -D Ifpack2_ENABLE_TESTS:BOOL=OFF \
  -D Trilinos_ENABLE_Stratimikos:BOOL=ON \
  -D Trilinos_ENABLE_FEI:BOOL=ON \
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
  -D Trilinos_ENABLE_Pike:BOOL=ON \
  $SRC_DIR

ninja -j $CPU_COUNT
ninja install
