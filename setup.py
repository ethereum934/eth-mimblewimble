import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

with open('requirements.txt') as f:
    required = f.read().splitlines()

setuptools.setup(
    name="py934",
    version="0.0.1",
    author="Wanseob Lim",
    author_email="email@wanseob.com",
    description="Python library for Ethereum 9 3/4",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ethereum/eth-mimblewimble",
    packages=setuptools.find_packages(),
    install_requires=required,
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
        "Operating System :: OS Independent",
    ],
)
