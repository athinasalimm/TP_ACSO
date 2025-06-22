# Compiler settings
CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread -g

# Build target
TARGET = threadpool
SRC = thread-pool.cc Semaphore.cc main.cc

# Default target
all: $(TARGET)

# Main compilation rule
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

# Rule expected by tester.sh
custom: $(TARGET)

# Clean up build artifacts
clean:
	rm -f $(TARGET)

.PHONY: all clean custom