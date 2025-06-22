# Compiler settings
CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread -g

# Build target
TARGET = test_custom

# Default target
all: $(TARGET)

# Build the main target
$(TARGET): thread-pool.cc Semaphore.cc test_custom.cc
	$(CXX) $(CXXFLAGS) -o $@ $^

# Custom build target (como lo espera tester.sh)
custom:
	$(CXX) $(CXXFLAGS) -o $(TARGET) thread-pool.cc Semaphore.cc test_custom.cc

# Clean up build artifacts
clean:
	rm -f $(TARGET)

.PHONY: all clean custom