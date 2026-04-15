@echo off
REM Docker Deployment Script for Vegetable Detection (Windows)
REM Provides convenient commands for building and running Docker containers
REM
REM Usage: deploy_docker.bat [command] [options]
REM
REM Examples:
REM   deploy_docker.bat build gpu
REM   deploy_docker.bat run gpu inference
REM   deploy_docker.bat train gpu
REM   deploy_docker.bat jupyter
REM   deploy_docker.bat compose up

setlocal enabledelayedexpansion

REM Configuration
set "PROJECT_NAME=veggie-detection"
set "COMMAND=%1"
set "ARG1=%2"
set "ARG2=%3"
set "ARG3=%4"

REM Helper functions
:print_header
echo.
echo ============================================================
echo %~1
echo ============================================================
exit /b 0

:print_success
echo [SUCCESS] %~1
exit /b 0

:print_error
echo [ERROR] %~1
exit /b 0

:print_info
echo [INFO] %~1
exit /b 0

:show_usage
echo.
echo Vegetable Detection Docker Deployment Script
echo.
echo USAGE:
echo   deploy_docker.bat [command] [args]
echo.
echo COMMANDS:
echo.
echo BUILD:
echo   build gpu                   Build GPU image
echo   build cpu                   Build CPU image
echo   build jetson                Build Jetson image
echo   build jupyter               Build Jupyter development image
echo   build export                Build model export image
echo   build all                   Build all images
echo.
echo RUN INFERENCE:
echo   run gpu inference           Run inference on GPU
echo   run cpu inference           Run inference on CPU
echo.
echo TRAINING:
echo   train gpu [epochs] [batch]  Train on GPU
echo   train cpu [epochs] [batch]  Train on CPU
echo.
echo JUPYTER:
echo   jupyter                     Start Jupyter Lab
echo.
echo DOCKER COMPOSE:
echo   compose up                  Start all services
echo   compose down                Stop all services
echo   compose logs                View logs
echo.
echo SYSTEM:
echo   clean                       Remove all containers/images
echo   help                        Show this help message
echo.
exit /b 0

REM Check if Docker is installed
:check_docker
docker --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not installed. Please install Docker first."
    exit /b 1
)
for /f "tokens=*" %%i in ('docker --version') do set "DOCKER_VERSION=%%i"
call :print_success "Docker found: %DOCKER_VERSION%"
exit /b 0

REM Build Docker images
:build_image
if "%ARG1%"=="" (
    call :print_error "Please specify image type: gpu, cpu, jetson, jupyter, export, or all"
    exit /b 1
)

if "%ARG1%"=="gpu" (
    call :print_header "Building GPU image"
    docker build -f docker/Dockerfile -t %PROJECT_NAME%:gpu .
    if errorlevel 1 (
        call :print_error "Failed to build GPU image"
        exit /b 1
    )
    call :print_success "GPU image built: %PROJECT_NAME%:gpu"
) else if "%ARG1%"=="cpu" (
    call :print_header "Building CPU image"
    docker build -f docker/Dockerfile-cpu -t %PROJECT_NAME%:cpu .
    if errorlevel 1 (
        call :print_error "Failed to build CPU image"
        exit /b 1
    )
    call :print_success "CPU image built: %PROJECT_NAME%:cpu"
) else if "%ARG1%"=="jetson" (
    call :print_header "Building Jetson image"
    docker build -f docker/Dockerfile-jetson-jetpack5 -t %PROJECT_NAME%:jetson .
    if errorlevel 1 (
        call :print_error "Failed to build Jetson image"
        exit /b 1
    )
    call :print_success "Jetson image built: %PROJECT_NAME%:jetson"
) else if "%ARG1%"=="jupyter" (
    call :print_header "Building Jupyter image"
    docker build -f docker/Dockerfile-jupyter -t %PROJECT_NAME%:jupyter .
    if errorlevel 1 (
        call :print_error "Failed to build Jupyter image"
        exit /b 1
    )
    call :print_success "Jupyter image built: %PROJECT_NAME%:jupyter"
) else if "%ARG1%"=="export" (
    call :print_header "Building Export image"
    docker build -f docker/Dockerfile-export -t %PROJECT_NAME%:export .
    if errorlevel 1 (
        call :print_error "Failed to build Export image"
        exit /b 1
    )
    call :print_success "Export image built: %PROJECT_NAME%:export"
) else if "%ARG1%"=="all" (
    call :build_image gpu
    call :build_image cpu
    call :build_image jetson
    call :build_image jupyter
    call :build_image export
) else (
    call :print_error "Unknown image type: %ARG1%"
    exit /b 1
)
exit /b 0

REM Run inference
:run_inference
if "%ARG1%"=="" (
    call :print_error "Please specify platform: gpu or cpu"
    exit /b 1
)

set "INPUT=%ARG2%"
if "%INPUT%"=="" set "INPUT=."

call :print_header "Running inference on %ARG1%"

if "%ARG1%"=="gpu" (
    docker run --rm --gpus all ^
        -v %cd%\data:/data ^
        -v %cd%\runs:/workspace/runs ^
        %PROJECT_NAME%:gpu ^
        detect predict model=yolov11s.pt source=%INPUT% save=True
) else if "%ARG1%"=="cpu" (
    docker run --rm ^
        -v %cd%\data:/data ^
        -v %cd%\runs:/workspace/runs ^
        %PROJECT_NAME%:cpu ^
        detect predict model=yolov11s.pt source=%INPUT% save=True
) else (
    call :print_error "Unknown platform: %ARG1%"
    exit /b 1
)

if errorlevel 1 (
    call :print_error "Inference failed"
    exit /b 1
)
call :print_success "Inference completed. Results in .\runs"
exit /b 0

REM Run training
:run_training
if "%ARG1%"=="" (
    call :print_error "Please specify platform: gpu or cpu"
    exit /b 1
)

set "EPOCHS=%ARG2%"
if "%EPOCHS%"=="" set "EPOCHS=100"

set "BATCH=%ARG3%"
if "%BATCH%"=="" set "BATCH=32"

call :print_header "Training on %ARG1%"

if "%ARG1%"=="gpu" (
    docker run --rm --gpus all ^
        -v %cd%\data:/data ^
        -v %cd%\weights:/workspace/weights ^
        -v %cd%\runs:/workspace/runs ^
        %PROJECT_NAME%:gpu ^
        detect train model=yolov11s.yaml data=/data/data.yaml ^
            epochs=%EPOCHS% batch=%BATCH% device=0
) else if "%ARG1%"=="cpu" (
    docker run --rm ^
        -v %cd%\data:/data ^
        -v %cd%\weights:/workspace/weights ^
        -v %cd%\runs:/workspace/runs ^
        %PROJECT_NAME%:cpu ^
        detect train model=yolov11s.yaml data=/data/data.yaml ^
            epochs=%EPOCHS% batch=%BATCH% device=0
) else (
    call :print_error "Unknown platform: %ARG1%"
    exit /b 1
)

if errorlevel 1 (
    call :print_error "Training failed"
    exit /b 1
)
call :print_success "Training completed"
exit /b 0

REM Start Jupyter
:start_jupyter
call :print_header "Starting Jupyter Lab"

docker run --rm -d ^
    --name %PROJECT_NAME%-jupyter ^
    --gpus all ^
    -p 8888:8888 ^
    -v %cd%\data:/data ^
    -v %cd%\notebooks:/workspace/notebooks ^
    -v %cd%\weights:/workspace/weights ^
    %PROJECT_NAME%:jupyter

if errorlevel 1 (
    call :print_error "Failed to start Jupyter"
    exit /b 1
)
call :print_success "Jupyter Lab started"
call :print_info "Access at http://localhost:8888"
call :print_info "To stop: docker stop %PROJECT_NAME%-jupyter"
exit /b 0

REM Docker Compose operations
:compose_op
if "%ARG1%"=="" (
    call :print_error "Please specify compose operation: up, down, logs, or remove"
    exit /b 1
)

if "%ARG1%"=="up" (
    call :print_header "Starting Docker Compose services"
    docker-compose up -d
    if errorlevel 1 (
        call :print_error "Failed to start services"
        exit /b 1
    )
    call :print_success "Services started"
    docker-compose ps
) else if "%ARG1%"=="down" (
    call :print_header "Stopping Docker Compose services"
    docker-compose down
    if errorlevel 1 (
        call :print_error "Failed to stop services"
        exit /b 1
    )
    call :print_success "Services stopped"
) else if "%ARG1%"=="logs" (
    docker-compose logs -f
) else if "%ARG1%"=="remove" (
    call :print_header "Removing Docker Compose services and volumes"
    docker-compose down -v
    if errorlevel 1 (
        call :print_error "Failed to remove services"
        exit /b 1
    )
    call :print_success "Services and volumes removed"
) else (
    call :print_error "Unknown compose operation: %ARG1%"
    exit /b 1
)
exit /b 0

REM Clean up containers and images
:clean
call :print_header "Cleaning up Docker resources"
REM Stop and remove containers
for /f "tokens=1" %%i in ('docker ps -a --filter "name=%PROJECT_NAME%" --quiet') do (
    docker rm -f %%i
)
REM Remove images
for /f "tokens=1" %%i in ('docker images --filter "reference=%PROJECT_NAME%*" --quiet') do (
    docker rmi -f %%i
)
call :print_success "Docker resources cleaned"
exit /b 0

REM Main logic
:main
call :check_docker

if "%COMMAND%"=="" (
    call :show_usage
    exit /b 0
)

if "%COMMAND%"=="build" (
    call :build_image
) else if "%COMMAND%"=="run" (
    call :run_inference
) else if "%COMMAND%"=="train" (
    call :run_training
) else if "%COMMAND%"=="jupyter" (
    call :start_jupyter
) else if "%COMMAND%"=="compose" (
    call :compose_op
) else if "%COMMAND%"=="clean" (
    call :clean
) else if "%COMMAND%"=="help" (
    call :show_usage
) else (
    call :print_error "Unknown command: %COMMAND%"
    echo Run 'deploy_docker.bat help' for usage information
    exit /b 1
)

exit /b 0

REM Execute main
call :main
