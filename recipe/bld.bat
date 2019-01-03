
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
    -DTrilinos_ENABLE_Teuchos:BOOL=ON ^
    -DTrilinos_ENABLE_ROL:BOOL=ON ^
    ..
if errorlevel 1 exit 1

cmake --build . --config Release --target install
if errorlevel 1 exit 1
