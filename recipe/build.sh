mkdir -p build
cd build

ENABLE_PIRO=ON
if [ $(uname) == Darwin ]; then
    export CXXFLAGS="$CXXFLAGS -stdlib=libc++"
    ENABLE_PIRO=OFF #Piro fails to compile on OSX
fi

export MPI_FLAGS="--allow-run-as-root"

if [ $(uname) == Linux ]; then
    export MPI_FLAGS="$MPI_FLAGS;-mca;plm;isolated"
fi

cmake \
  -D CMAKE_BUILD_TYPE:STRING=RELEASE \
  -D CMAKE_INSTALL_PREFIX:PATH=$PREFIX \
  -D BUILD_SHARED_LIBS:BOOL=ON \
  -D TPL_ENABLE_MPI:BOOL=ON \
  -D MPI_BASE_DIR:PATH=$PREFIX \
  -D MPI_EXEC:FILEPATH=$PREFIX/bin/mpiexec \
  -D PYTHON_EXECUTABLE:FILEPATH=$PYTHON \
  -D Trilinos_ENABLE_Fortran:BOOL=OFF \
  -D TPL_ENABLE_HDF5:BOOL=ON \
  -D TPL_ENABLE_Kokkos:BOOL=ON \
  -D Kokkos_DIR=$PREFIX \
  -D Kokkos_ROOT=$PREFIX \
  -D TPL_ENABLE_KokkosKernels=ON \
  -D KokkosKernels_ROOT=$PREFIX \
  -D KokkosKernels_DIR=$PREFIX \
  -D Tpetra_IGNORE_KOKKOS_COMPATIBILITY=ON \
  -D Trilinos_ENABLE_OpenMP:BOOL=ON \
  -D Tpetra_INST_OPENMP:BOOL=ON \
  -D Tpetra_INST_SERIAL:BOOL=ON \
  -D Trilinos_ENABLE_ALL_PACKAGES=ON \
  -D Trilinos_ENABLE_TESTS=OFF \
  -D Trilinos_ENABLE_EXAMPLES:BOOL=OFF \
  -D Trilinos_ENABLE_Piro=${ENABLE_PIRO} \
  -D Trilinos_ENABLE_SEACAS=OFF \
  -D Trilinos_ENABLE_EPETRA=OFF \
  -D Trilinos_ENABLE_ISORROPIA=OFF \
  -D Trilinos_ENABLE_Intrepid=OFF \
  -D Trilinos_ENABLE_AMESOS=OFF \
  -D Trilinos_ENABLE_ML=OFF \
  -D Trilinos_ENABLE_IFpack=OFF \
  -D Trilinos_ENABLE_Krino=OFF \
  -D Trilinos_ENABLE_Percept=OFF \
  -D Trilinos_ENABLE_STK=OFF \
  -D Trilinos_ENABLE_Pytrilinos=OFF \
  -D Trilinos_ENABLE_ShyLU_DDCore=OFF \
  -D Trilinos_ENABLE_ShyLU_DD=OFF \
  -D Trilinos_ENABLE_Triutils=OFF \
  -D Trilinos_ENABLE_EPETRAEXT=OFF \
  -D Trilinos_ENABLE_AzteCOO=OFF \
  -D Trilinos_ENABLE_ThyraEpetraAdapters=OFF \
  -D Trilinos_ENABLE_ThyraEpetraExtAdapters=OFF \
  $SRC_DIR

make -j $CPU_COUNT install
