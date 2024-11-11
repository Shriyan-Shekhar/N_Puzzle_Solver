# N-Puzzle Solver
**Stage 1: </br>**
**Game Play:**
A, W, S, D keys for movement: </br>
```A: Left``` </br>
```W: Up``` </br>
```S: Down```</br>
```D: Right``` </br>
</br>
To download the environment, follow the google drive link below: </br>
https://drive.google.com/file/d/1bVLqvVLlR-rDK_lpem0LAiHADqKcoco9/view?usp=sharing

Download the Mars.jar file and run puzzle_solver.asm there.

**Stage 2: </br>**
Automatic game solver through A-star using three heuristics - Misplaced Tiles, Manhattan Distance, Mostow Prieditis </br>
The code for Misplaced Tiles can be run as follows: <br>
```python N_Puzzle_A_Star.py -p puzzle_1.txt -H 1 -o output1.txt```

The code for Manhattan Distance can be run as follows: <br>
```python N_Puzzle_A_Star.py -p puzzle_1.txt -H 2 -o output1.txt```

The code for Mostow Prieditis can be run as follows: <br>
```python N_Puzzle_A_Star.py -p puzzle_1.txt -H 3 -o output1.txt```

There are 5 input puzzles, feel free to change it and run the search (Do not forget to cd into the A-star folder)
