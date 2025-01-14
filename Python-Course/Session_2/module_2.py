# from collections import defaultdict as dd
# from itertools import product
from itertools import product
from typing import Any, Dict, List, Tuple


def task_1(data_1: Dict[str, int], data_2: Dict[str, int]):
    res_dict = data_1.copy()

    for key, value in data_2.items():
        if key in res_dict:
            res_dict[key] += value
        else:
            res_dict[key] = value
    return res_dict


def task_2():
    res_dict = dict()
    for i in range(1, 16):
        res_dict[i] = i*i
    return res_dict


def task_3(data: Dict[Any, List[str]]):
    res_list = [''.join(let) for let in product(*data.values())]
    return res_list


def task_4(data: Dict[str, int]):
    if len(data) <= 3:
        return list(data.keys())
    sorted_dict = sorted(data.items(), key=lambda x: x[1], reverse=True)[:3]
    return [key for key, value in sorted_dict]


def task_5(data: List[Tuple[Any, Any]]) -> Dict[str, List[int]]:
    res_dict = dict()
    for key, val in data:
        if key not in res_dict:
            res_dict[key] = []
        res_dict[key].append(val)
    return res_dict


def task_6(data: List[Any]):
    pass


def task_7(words: [List[str]]) -> str:
    pass


def task_8(haystack: str, needle: str) -> int:
    pass
