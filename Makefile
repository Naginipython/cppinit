files := $(wildcard src/*.cpp)
files_no_main := $(filter-out src/main.cpp, $(files))
test_files := $(wildcard tests/*.cpp)

# Compiler settings
CXX := g++
CXXFLAGS := -Iinclude -Wall -g
LIBS :=
TESTFLAGS := -lgtest -lgtest_main -pthread

# Object files
obj_files := $(patsubst src/%.cpp, obj/%.o, $(files))
obj_files_no_main := $(patsubst src/%.cpp, obj/%.o, $(files_no_main))
test_obj_files := $(patsubst tests/%.cpp, test_obj/%.o, $(test_files))

# Create obj and test_obj directories if they don't exist
$(shell mkdir -p obj test_obj)

all: main

main: $(obj_files)
	$(CXX) $(CXXFLAGS) $(obj_files) -o main $(LIBS)

obj/%.o: src/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: main
	./main

test: $(test_obj_files) $(patsubst src/%.cpp, test_obj/%.o, $(files_no_main))
	$(CXX) $(CXXFLAGS) $(patsubst src/%.cpp, test_obj/%.o, $(files_no_main)) $(test_obj_files) $(TESTFLAGS) -o test_main $(LIBS)
	./test_main

test_obj/%.o: tests/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

test_obj/%.o: src/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf main test_main obj/ test_obj/
