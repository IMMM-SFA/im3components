from typing import Union


def py_demo(x: Union[int, float], y: Union[int, float]) -> Union[int, float]:
    """Add together two numbers that have been squared.

    :param x:                   Some number
    :type x:                    Union[int, float]

    :param y:                   Some number
    :type y:                    Union[int, float]

    :return:                    Numeric result

    """

    return (x*2)**2 + y**2
