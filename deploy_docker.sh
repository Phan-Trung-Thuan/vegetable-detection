#!/bin/bash

# Docker Deployment Script for Vegetable Detection
# Provides convenient commands for building and running Docker containers
# 
# Usage: ./deploy_docker.sh [command] [options]
#
# Examples:
#   ./deploy_docker.sh build gpu              # Build GPU image
#   ./deploy_docker.sh run gpu inference      # Run GPU inference
#   ./deploy_docker.sh train gpu              # Run training on GPU
#   ./deploy_docker.sh jupyter                # Start Jupyter
#   ./deploy_docker.sh compose up             # Start all services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="veggie-detection"
REGISTRY="${DOCKER_REGISTRY:-}"  # Set to registry URL if using remote registry
TAG="${1:-}"

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

show_usage() {
    cat << EOF
${BLUE}Vegetable Detection Docker Deployment Script${NC}

${YELLOW}USAGE:${NC}
  ./deploy_docker.sh [command] [args]

${YELLOW}COMMANDS:${NC}

${GREEN}BUILD:${NC}
  build gpu                       Build GPU image
  build cpu                       Build CPU image
  build jetson                    Build Jetson image (JetPack 5)
  build jupyter                   Build Jupyter development image
  build export                    Build model export image
  build all                       Build all images

${GREEN}RUN INFERENCE:${NC}
  run gpu inference [image_path]  Run inference on GPU
  run cpu inference [image_path]  Run inference on CPU
  run jetson inference            Run inference on Jetson

${GREEN}TRAINING:${NC}
  train gpu [epochs] [batch]      Train on GPU
  train cpu [epochs] [batch]      Train on CPU

${GREEN}JUPYTER:${NC}
  jupyter                         Start Jupyter Lab on port 8888

${GREEN}DOCKER COMPOSE:${NC}
  compose up                      Start all services
  compose down                    Stop all services
  compose logs                    View logs
  compose remove                  Remove containers and volumes

${GREEN}EXPORT:${NC}
  export onnx                     Export model to ONNX
  export tflite                   Export model to TFLite
  export engine                   Export model to TensorRT

${GREEN}SYSTEM:${NC}
  clean                           Remove all veggie containers/images
  prune                           Prune unused Docker resources
  help                            Show this help message
  version                         Show version info

${YELLOW}EXAMPLES:${NC}
  ./deploy_docker.sh build gpu
  ./deploy_docker.sh run gpu inference ./data/image.jpg
  ./deploy_docker.sh train gpu 100 32
  ./deploy_docker.sh compose up
  ./deploy_docker.sh jupyter

EOF
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker found: $(docker --version)"
}

# Check if nvidia-docker is available (for GPU)
check_nvidia_docker() {
    if ! command -v nvidia-docker &> /dev/null && ! docker plugin ls | grep -q nvidia; then
        print_info "NVIDIA Docker not found. GPU support may not work."
        return 1
    fi
    return 0
}

# Build Docker images
build_image() {
    local image_type=$1
    print_header "Building ${image_type} image"
    
    case $image_type in
        gpu)
            docker build -f docker/Dockerfile -t ${PROJECT_NAME}:gpu .
            print_success "GPU image built: ${PROJECT_NAME}:gpu"
            ;;
        cpu)
            docker build -f docker/Dockerfile-cpu -t ${PROJECT_NAME}:cpu .
            print_success "CPU image built: ${PROJECT_NAME}:cpu"
            ;;
        jetson)
            docker build -f docker/Dockerfile-jetson-jetpack5 -t ${PROJECT_NAME}:jetson .
            print_success "Jetson image built: ${PROJECT_NAME}:jetson"
            ;;
        jupyter)
            docker build -f docker/Dockerfile-jupyter -t ${PROJECT_NAME}:jupyter .
            print_success "Jupyter image built: ${PROJECT_NAME}:jupyter"
            ;;
        export)
            docker build -f docker/Dockerfile-export -t ${PROJECT_NAME}:export .
            print_success "Export image built: ${PROJECT_NAME}:export"
            ;;
        all)
            for img in gpu cpu jetson jupyter export; do
                build_image $img
            done
            return
            ;;
        *)
            print_error "Unknown image type: $image_type"
            return 1
            ;;
    esac
}

# Run inference
run_inference() {
    local platform=$1
    local input=${2:-.}
    
    print_header "Running inference on ${platform}"
    local image="${PROJECT_NAME}:${platform}"
    
    docker run --rm \
        $([ "$platform" != "cpu" ] && echo "--gpus all") \
        -v $(pwd)/data:/data \
        -v $(pwd)/runs:/workspace/runs \
        $image \
        detect predict model=yolov11s.pt source=$input save=True
    
    print_success "Inference completed. Results in ./runs"
}

# Run training
run_training() {
    local platform=$1
    local epochs=${2:-100}
    local batch=${3:-32}
    
    print_header "Training on ${platform}"
    local image="${PROJECT_NAME}:${platform}"
    
    docker run --rm \
        $([ "$platform" != "cpu" ] && echo "--gpus all") \
        -v $(pwd)/data:/data \
        -v $(pwd)/weights:/workspace/weights \
        -v $(pwd)/runs:/workspace/runs \
        $image \
        detect train model=yolov11s.yaml data=/data/data.yaml \
            epochs=$epochs batch=$batch device=0
    
    print_success "Training completed"
}

# Start Jupyter
start_jupyter() {
    print_header "Starting Jupyter Lab"
    
    docker run --rm -d \
        --name ${PROJECT_NAME}-jupyter \
        --gpus all \
        -p 8888:8888 \
        -v $(pwd)/data:/data \
        -v $(pwd)/notebooks:/workspace/notebooks \
        -v $(pwd)/weights:/workspace/weights \
        ${PROJECT_NAME}:jupyter
    
    print_success "Jupyter Lab started"
    print_info "Access at http://localhost:8888"
    print_info "To stop: docker stop ${PROJECT_NAME}-jupyter"
}

# Docker Compose operations
docker_compose_op() {
    local operation=$1
    
    case $operation in
        up)
            print_header "Starting Docker Compose services"
            docker-compose up -d
            print_success "Services started"
            docker-compose ps
            ;;
        down)
            print_header "Stopping Docker Compose services"
            docker-compose down
            print_success "Services stopped"
            ;;
        logs)
            docker-compose logs -f
            ;;
        remove)
            print_header "Removing Docker Compose services and volumes"
            docker-compose down -v
            print_success "Services and volumes removed"
            ;;
        *)
            print_error "Unknown compose operation: $operation"
            return 1
            ;;
    esac
}

# Export model to different formats
export_model() {
    local format=$1
    local model=${2:-weights/best.pt}
    
    print_header "Exporting model to ${format}"
    
    docker run --rm \
        --gpus all \
        -v $(pwd)/weights:/weights \
        ${PROJECT_NAME}:export \
        yolo detect export model=$model format=$format imgsz=640
    
    print_success "Model exported to $format"
}

# Clean up containers and images
clean() {
    print_header "Cleaning up Docker resources"
    
    # Stop running containers
    docker ps -a | grep ${PROJECT_NAME} | awk '{print $1}' | xargs -r docker rm -f
    
    # Remove images
    docker images | grep ${PROJECT_NAME} | awk '{print $3}' | xargs -r docker rmi -f
    
    print_success "Docker resources cleaned"
}

# Prune unused resources
prune() {
    print_header "Pruning Docker system"
    docker system prune -f
    print_success "Docker system pruned"
}

# Main script logic
main() {
    local command=$1
    
    check_docker
    
    case $command in
        build)
            build_image $2
            ;;
        run)
            run_inference $2 $3
            ;;
        train)
            run_training $2 $3 $4
            ;;
        jupyter)
            start_jupyter
            ;;
        compose)
            docker_compose_op $2
            ;;
        export)
            export_model $2 $3
            ;;
        clean)
            clean
            ;;
        prune)
            prune
            ;;
        help|--help|-h)
            show_usage
            ;;
        version|--version|-v)
            print_info "Vegetable Detection v1.0"
            ;;
        *)
            if [ -z "$command" ]; then
                show_usage
            else
                print_error "Unknown command: $command"
                echo "Run './deploy_docker.sh help' for usage information"
            fi
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
