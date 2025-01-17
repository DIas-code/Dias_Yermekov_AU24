from collections import Counter
import os
# from idlelib.iomenu import encoding
from pathlib import Path
import re
from random import choice
from random import seed
from typing import List, Union

import requests
# from requests.exceptions import ConnectionError
# from gensim.utils import simple_preprocess


S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"


def task_1():
    seed(1)

    with open(PATH_TO_NAMES, 'r', encoding="utf-8") as names_file:
        names = [name.strip().lower() for name in names_file]
    names.sort()
    with open(PATH_TO_SURNAMES, 'r', encoding="utf-8") as surnames_file:
        surnames = [surname.strip().lower() for surname in surnames_file]
    sorted_ns = [f'{name} {choice(surnames)}' for name in names]
    with open(PATH_TO_OUTPUT, 'w', encoding="utf8") as sn_file:
        sn_file.write("\n".join(sorted_ns))


def task_2(top_k: int):
    with open(PATH_TO_TEXT, 'r', encoding="utf-8") as text_file:
        text = text_file.read().lower()

    with open(PATH_TO_STOP_WORDS, 'r', encoding="utf-8") as stop_file:
        stop_words = set(word.strip().lower() for word in stop_file)

    words = re.findall(r'\b[a-z]+\b', text)
    stop_words_not_in_text = [word for word in words if word not in stop_words]
    words_cnt = Counter(stop_words_not_in_text)
    top_words = words_cnt.most_common(top_k)
    return top_words


def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except requests.exceptions.RequestException as e:
        raise requests.exceptions.RequestException(e)


def task_4(data: List[Union[int, str, float]]):
    tsum = 0.0
    for num in data:
        try:
            tsum += float(num)
        except TypeError as e:
            raise e
    return tsum


def task_5():
    try:
        a, b = input().split()
        a, b = float(a), float(b)
        if b == 0:
            print("Can't divide by zero")
        else:
            print(a/b)
    except ValueError:
        print("Entered value is wrong")
