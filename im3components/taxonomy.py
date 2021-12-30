from dataclasses import dataclass, field, fields, MISSING
from enum import Enum
from typing import List


class Language(Enum):
    PYTHON = 'Python'
    r = 'R'
    julia = 'Julia'
    bash = 'Bash'


@dataclass
class Component:
    name: str
    description: str
    language: Language
    package: str
    method: str
    from_models: List[str] = field(default_factory=list)
    to_models: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)

    def is_related(self, search: str):
        return search.casefold() in ' '.join(
            (self.tags if self.tags is not None else []) +
            (self.from_models if self.from_models is not None else []) +
            (self.to_models if self.to_models is not None else []) +
            ([self.language] if self.language is not None else [])
        ).casefold()


@dataclass
class Model:
    name: str


@dataclass
class Experiment:
    name: str
