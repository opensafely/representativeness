# OpenSAFELY: Representativeness of electronic health record platform OpenSAFELY-TPP data compared to the population of England

This is the code and configuration for an OpenSAFELY project looking at the representativeness of OpenSAFELY-TPP data

* The paper is [here](https://doi.org/10.12688/wellcomeopenres.18010.1)
* If you are interested in how we defined our variables, take a look at the [study definition](https://github.com/opensafely/representativeness/blob/master/analysis/study_definition.py); this is written in python, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](https://github.com/opensafely/representativeness/tree/master/codelists).
* Developers and epidemiologists interested in the framework should review the [OpenSAFELY documentation](https://docs.opensafely.org)

# About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).
