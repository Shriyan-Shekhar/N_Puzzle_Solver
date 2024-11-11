import argparse
import numpy as np
import heapq

class Puzzle(object):
    def __init__(self, file_path=None, puzzle=None):
        self.size = 3
        self.goal_puzzle = np.array([[1, 2, 3],[8, 0, 4],[7, 6, 5]])

        if puzzle is not None:
            self.puzzle = puzzle
        elif file_path is not None:
            self.puzzle = self.read_puzzle(file_path)
            assert self.is_solvable(self.puzzle), '8-puzzle has an unsolvable initial state.'
        else:
            self.puzzle = self.make_puzzle()

    def __hash__(self):
        return hash(tuple(map(tuple, self.puzzle)))  # Create a hash based on the puzzle state

    def __eq__(self, other):
        return isinstance(other, Puzzle) and np.array_equal(self.puzzle, other.puzzle) # Compare based on the puzzle state

            
    def make_puzzle(self):
        tiles = range(self.size ** 2)
        tiles = list(tiles)
        np.random.shuffle(tiles)

        while not self.is_solvable(np.array(tiles).reshape((self.size, self.size))):
            np.random.shuffle(tiles)

        return np.array(tiles).reshape((self.size, self.size))
    
    def read_puzzle(self, file_path):
        with open(file_path, 'r') as file:
            puzzle = np.array([list(map(int, line.strip().split())) for line in file.readlines()])
            assert puzzle.shape[0]==self.size and puzzle.shape[1]==self.size, "8-puzzle should have a 3 * 3 board."
        return puzzle

    def is_solvable(self, puzzle):
        # Based on http://math.stackexchange.com/questions/293527/how-to-check-if-a-8-puzzle-is-solvable
        goal_puzzle = self.goal_puzzle.flatten()
        goal_inversions = 0
        for i in range(len(goal_puzzle)):
            for j in range(i+1, len(goal_puzzle)):
                if goal_puzzle[i] > goal_puzzle[j] and goal_puzzle[i] != 0 and goal_puzzle[j] != 0:
                    goal_inversions += 1

        puzzle = puzzle.flatten()
        inversions = 0
        for i in range(len(puzzle)):
            for j in range(i+1, len(puzzle)):
                if puzzle[i] > puzzle[j] and puzzle[i] != 0 and puzzle[j] != 0:
                    inversions += 1

        return inversions % 2 == goal_inversions % 2

    def misplaced_tiles(self):
        goal_positions = {
            1: (0, 0), 2: (0, 1), 3: (0, 2),
            8: (1, 0), 0: (1, 1), 4: (1, 2),
            7: (2, 0), 6: (2, 1), 5: (2, 2)  # 0 represents the empty space
        }
        count = 0

        for i in range (3):
            for j in range (3):
                value = self.puzzle[i][j]
                if value == 0:
                    continue
                else:
                    goal_row, goal_col = goal_positions[value]
                    if i != goal_row or j != goal_col:
                        count += 1
        h = count
        return h

    def manhattan_distance(self):
        goal_positions = {
            1: (0, 0), 2: (0, 1), 3: (0, 2),
            8: (1, 0), 0: (1, 1), 4: (1, 2),
            7: (2, 0), 6: (2, 1), 5: (2, 2)  # 0 represents the empty space
        }

        finding_h = 0

        for i in range (3):
            for j in range (3):
                if self.puzzle[i][j] == 0: #ignore empty space
                    continue
                else:
                    goal_row, goal_col = goal_positions[self.puzzle[i][j]]
                    finding_h += abs(i - goal_row) 
                    finding_h += abs(j - goal_col)
        
        h = finding_h
        
        return h
    
    def nilsson_heuristic(self):
        #not admissible - this heuristic overestimates the cost to reach the goal therefore, inadmissible and omit from coding.
        return None
    
    def mostow_prieditis_heuristic(self):
        goal_positions = {
            1: (0, 0), 2: (0, 1), 3: (0, 2),
            8: (1, 0), 0: (1, 1), 4: (1, 2),
            7: (2, 0), 6: (2, 1), 5: (2, 2)  # 0 represents the empty space
        }
        out_of_row = 0
        out_of_col = 0

        for i in range (3):
            for j in range (3):
                value = self.puzzle [i][j]
                if value == 0:
                    continue
                else:
                    goal_row, goal_col = goal_positions[value]
                    if i != goal_row:
                        out_of_row += 1
                    
        for i in range (3):
            for j in range (3):
                value = self.puzzle [i][j]
                if value == 0:
                    continue
                else:
                    goal_row, goal_col = goal_positions[value]
                    if j != goal_col:
                        out_of_col += 1
                        
        h = out_of_row + out_of_col
        return h


def a_star_algorithm(puzzle_instance, heuristic):
    # Choose the heuristic function based on the input
    heuristic_function = {
        1: puzzle_instance.misplaced_tiles,
        2: puzzle_instance.manhattan_distance,
        4: puzzle_instance.mostow_prieditis_heuristic
    }.get(heuristic, puzzle_instance.misplaced_tiles)  # Default to Misplaced Tiles

    if puzzle_instance.is_solvable(puzzle_instance.puzzle) == False:
        return [], 0
    
    open_list = []
    start_puzzle = puzzle_instance  # Create a Puzzle instance
    heapq.heappush(open_list, (0, 0, start_puzzle))  # Push the start puzzle

    g_costs = {start_puzzle: 0}  # Use Puzzle instance as key
    came_from = {}
    num_node_expand = 0
    path = []

    unique_id = 1

    while open_list:
        current_cost, id, current_puzzle = heapq.heappop(open_list)
        num_node_expand += 1

        
        # Check if the current puzzle matches the goal state
        if np.array_equal(current_puzzle.puzzle, current_puzzle.goal_puzzle):
            # Reconstruct the path
            while current_puzzle in came_from:
                path.append(current_puzzle)
                current_puzzle = came_from[current_puzzle]
            path.append(start_puzzle)
            path.reverse()  # Reverse to get the correct order
            return path, num_node_expand  # Return the required values

        # Find the position of the zero tile
        zero_pos = np.argwhere(current_puzzle.puzzle == 0)[0]
        zero_row, zero_col = zero_pos

        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # Possible movements: up, down, left, right

        for horizontal, vertical in directions:
            new_row = zero_row + horizontal
            new_col = zero_col + vertical
            if 0 <= new_row < 3 and 0 <= new_col < 3:
                
                new_puzzle_array = current_puzzle.puzzle.copy()
                new_puzzle_array[zero_row][zero_col] = new_puzzle_array[new_row][new_col]
                new_puzzle_array[new_row][new_col] = 0
                new_puzzle = Puzzle(puzzle=new_puzzle_array)
                
                lowest_g_cost = g_costs[current_puzzle] + 1
                
                if new_puzzle not in g_costs:
                    came_from[new_puzzle] = current_puzzle
                    g_costs[new_puzzle] = lowest_g_cost
                    f_cost = lowest_g_cost + heuristic(new_puzzle) # Call the heuristic
                    heapq.heappush(open_list, (f_cost, unique_id, new_puzzle))
                    unique_id += 1

                elif (new_puzzle in g_costs):
                    if (lowest_g_cost < g_costs[new_puzzle]):
                        came_from[new_puzzle] = current_puzzle
                        g_costs[new_puzzle] = lowest_g_cost
                        f_cost = lowest_g_cost + heuristic(new_puzzle) # Call the heuristic
                        if not any(new_puzzle == item[2] for item in open_list):
                            heapq.heappush(open_list, (f_cost, unique_id, new_puzzle))
                            unique_id += 1

    return [], num_node_expand  # Return empty path if no solution is found
    
def write_output(name, data, student_id):
    with open(name, 'w') as file:
        file.write(str(student_id) + '\n')
        for state in data:
            for row in state.puzzle:
                file.write(' '.join(map(str, row)) + '\n')
            file.write('\n')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--puzzle", default="puzzle_1.txt", help="Path to txt file containing 8-puzzle")
    parser.add_argument("-H", "--heuristic", type=int, help="Heuristic mode to use. 1: Use Misplaced Tiles; 2: Use Manhattan distance; 3: Use Nilsson Heuristic; 4: Use Mostow and Prieditis Heuristic", default=1, choices=[1, 2, 3, 4]) # You can change the allowable values to only those representing admissible heuristics
    parser.add_argument("-o", "--output_file", default="output_1.txt", help="Path to output txt file")

    args = parser.parse_args()

    if args.puzzle:
        initial_state = Puzzle(args.puzzle)
    else:
        initial_state = Puzzle()

    heuristic_idx = {
    1: "Misplaced Tiles",
    2: "Manhattan Distance",
    3: "Mostow and Prieditis Heuristic",
    }

    heuristics = {
    "Misplaced Tiles": lambda state: state.misplaced_tiles(),
    "Manhattan Distance": lambda state: state.manhattan_distance(),
    "Mostow and Prieditis Heuristic": lambda state: state.mostow_prieditis_heuristic(),
    }
    
    name = heuristic_idx[args.heuristic]
    heuristic = heuristics[name]
    print(f"Using {name}:")
    if name == "Nilsson Heuristic":
        raise ValueError("Nilsson Heuristic is not admissible.")
    result_list = a_star_algorithm(initial_state, heuristic)
    if result_list:
        path, num_node_expand = result_list
        print(f"Solution found with {len(path) - 1} moves. {num_node_expand} nodes are expanded.")
        write_output(args.output_file, path, "12345678")
    else:
        print("No solution found.")