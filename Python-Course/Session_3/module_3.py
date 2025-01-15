# import time
import time
from turtledemo.penrose import start
from typing import List

Matrix = List[List[int]]


def task_1(exp: int):
    def power_f(num):
        return num ** exp
    return power_f


def task_2(*args, **kwags):
    for arg in args:
        print(arg)
    for val in kwags.values():
        print(val)


def helper(func):
    def wrapper(*args, **kwargs):
        print("Hi, friend! What's your name?")
        func(*args, **kwargs)
        print('See you soon!')
    return wrapper

@helper
def task_3(name: str):
    print(f"Hello! My name is {name}.")


def timer(func):
    def wrapper():
        start_time = time.time()
        func()
        end_time = time.time()
        run_time = end_time-start_time
        print(f"Finished {func.__name__} in {run_time:.4f} secs")
    return wrapper


@timer
def task_4():
    return len([1 for _ in range(0, 10**8)])


def task_5(matrix: Matrix) -> Matrix:
    col_len = len(matrix[0])
    row_len = len(matrix)
    t_matrix = [[0] * row_len for _ in range(col_len)]
    for i in range(row_len):
        for j in range(col_len):
            t_matrix[j][i] = matrix[i][j]
    return t_matrix


def task_6(queue: str):
    pass
