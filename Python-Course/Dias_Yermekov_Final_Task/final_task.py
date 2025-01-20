import sys
from argparse import ArgumentParser, ArgumentTypeError, FileType
from io import TextIOWrapper
from typing import Dict, List
import re
import json
import os
from pathlib import Path
FT_PATH = Path(os.path.realpath(__file__)).parent

DEFAULT_PATH_TO_STORE_INVERTED_INDEX = "inverted.index"
# DEFAULT_PATH_TO_STOP_WORDS = 'stop_words_en.txt'


class EncodedFileType(FileType):
    """File encoder"""

    def __call__(self, string):
        if string == "-":
            if "r" in self._mode:
                stdin = TextIOWrapper(sys.stdin.buffer, encoding=self._encoding)
                return stdin
            if "w" in self._mode:
                stdout = TextIOWrapper(sys.stdout.buffer, encoding=self._encoding)
                return stdout
            msg = 'argument "-" with mode %r' % self._mode
            raise ValueError(msg)

        try:
            return open(string, self._mode, self._bufsize, self._encoding, self._errors)
        except OSError as exception:
            args = {"filename": string, "error": exception}
            message = "can't open '%(filename)s': %(error)s"
            raise ArgumentTypeError(message % args)

    def print_encoder(self):
        """printer of encoder"""
        print(self._encoding)


class InvertedIndex:
    def __init__(self, words_ids: Dict[str, List[int]]):
        self.word_ids = words_ids

    def query(self, words: List[str]) -> List[int]:
        indexes = list()
        for word in words:
            if word in self.word_ids:
                indexes.extend(self.word_ids[word])
        return list(set(indexes))

    def dump(self, filepath: str) -> None:
        with open(filepath, 'w', encoding='utf-8') as file:
            json.dump(self.word_ids, file, ensure_ascii=False, indent=4)

    @classmethod
    def load(cls, filepath: str):
        with open(filepath, 'r', encoding='utf-8') as file:
            word_ids = json.load(file)
        return cls(word_ids)


def load_documents(filepath: str) -> Dict[int, str]:
    documents = dict()

    # with open(DEFAULT_PATH_TO_STOP_WORDS, 'r', encoding='utf-8') as f:
    #     stop_words = set(f.read().strip().splitlines())

    with open(FT_PATH / filepath, 'r', encoding='utf-8') as file:
        for line in file:
            doc_id, content = line.lower().split("\t", 1)
            doc_id = int(doc_id)
            words = re.split(r"\W+", content)
            # cleaned_words = [word for word in words if word not in stop_words]
            text = ' '.join(words)
            documents[doc_id] = str(text)
    return documents


def build_inverted_index(documents: Dict[int, str]) -> InvertedIndex:
    word_ids = dict()

    for doc_id, text in documents.items():
        words = text.split()

        for word in words:
            if word not in word_ids:
                word_ids[word] = []
            if doc_id not in word_ids[word]:
                word_ids[word].append(doc_id)

    return InvertedIndex(word_ids)


def callback_build(arguments) -> None:
    return process_build(arguments.dataset, arguments.output)


def process_build(dataset, output) -> None:
    documents: Dict[int, str] = load_documents(dataset)
    inverted_index = build_inverted_index(documents)
    inverted_index.dump(output)


def callback_query(arguments) -> None:
    process_query(arguments.query, arguments.index)


def process_query(queries, index) -> None:
    inverted_index = InvertedIndex.load(index)
    for query in queries:
        print(query[0])
        if isinstance(query, str):
            query = query.strip().split()

        doc_indexes = ",".join(str(value) for value in inverted_index.query(query))
        print(doc_indexes)


def setup_subparsers(parser) -> None:
    subparser = parser.add_subparsers(dest="command")
    build_parser = subparser.add_parser(
        "build",
        help="this parser is need to load, build"
        " and save inverted index bases on documents",
    )
    build_parser.add_argument(
        "-d",
        "--dataset",
        required=True,
        help="You should specify path to file with documents. ",
    )
    build_parser.add_argument(
        "-o",
        "--output",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="You should specify path to save inverted index. "
        "The default: %(default)s",
    )
    build_parser.set_defaults(callback=callback_build)

    query_parser = subparser.add_parser(
        "query", help="This parser is need to load and apply inverted index"
    )
    query_parser.add_argument(
        "--index",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="specify the path where inverted indexes are. " "The default: %(default)s",
    )
    query_file_group = query_parser.add_mutually_exclusive_group(required=True)
    query_file_group.add_argument(
        "-q",
        "--query",
        dest="query",
        action="append",
        nargs="+",
        help="you can specify a sequence of queries to process them overall",
    )
    query_file_group.add_argument(
        "--query_from_file",
        dest="query",
        type=EncodedFileType("r", encoding="utf-8"),
        default=TextIOWrapper(sys.stdin.buffer, encoding='utf-8'),
        help="query file to get queries for inverted index",
    )
    query_parser.set_defaults(callback=callback_query)


def main():
    parser = ArgumentParser(
        description="Inverted Index CLI is need to load, build,"
        "process query inverted index"
    )
    setup_subparsers(parser)
    arguments = parser.parse_args()
    arguments.callback(arguments)


if __name__ == "__main__":
    main()
