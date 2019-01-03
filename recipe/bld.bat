
del cmake\tribits\doc\developers_guide\TribitsBuildReference.html
rmdir /s /q cmake\tribits\examples\TribitsHelloWorld\hello_world
rmdir /s /q cmake\tribits\python_utils
del cmake\tribits\snapshot_tribits.py

mkdir build && cd build

cmake -LAH -G"NMake Makefiles" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%"  ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -DTrilinos_ENABLE_Fortran:BOOL=OFF ^
    -DTrilinos_ENABLE_ALL_PACKAGES:BOOL=OFF ^
    -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF ^
    -DTrilinos_ENABLE_TESTS:BOOL=OFF ^
    -DTrilinos_ENABLE_EXAMPLES:BOOL=OFF ^
    -DTrilinos_ENABLE_Shards:BOOL=ON ^
    -DTrilinos_ENABLE_GlobiPack:BOOL=ON ^
    -DTrilinos_ENABLE_Zoltan:BOOL=ON ^
    -DTrilinos_ENABLE_ROL:BOOL=ON ^
    -DTrilinos_ENABLE_RTOp:BOOL=ON ^
    -DTrilinos_ENABLE_Sacado:BOOL=ON ^
    -DTPL_BLAS_LIBRARIES=%LIBRARY_PREFIX:\=/%/lib/openblas.lib ^
    -DTPL_LAPACK_LIBRARIES=%LIBRARY_PREFIX:\=/%/lib/openblas.lib ^
    ..
if errorlevel 1 exit 1

cmake --build . --config Release --target install
if errorlevel 1 exit 1
