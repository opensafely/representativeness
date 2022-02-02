# LIBRARIES

# cohort extractor
from cohortextractor import StudyDefinition, patients
from codelists import *
from config import *
# set the index date
# STUDY POPULATION

study = StudyDefinition(
    index_date=index_date_death,
    default_expectations={
        "date": {
            "earliest": index_date,
            "latest": "today",
        },  # date range for simulated dates
        "rate": "uniform",
        "incidence": 1,
    },
    
    # This line defines the study population
    population = patients.registered_as_of("died_date"),

    died_date=patients.died_from_any_cause(
        between=[index_date_death,end_date],
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest" : end_date},
        },
    ),

    died_any=patients.died_from_any_cause(
        between=[index_date_death,end_date],
        returning="binary_flag",
        return_expectations={
            "rate" : "exponential_increase",
            "incidence": 0.4,
        },
    ),

    died_cause_ons=patients.died_from_any_cause(
        between=[index_date_death,end_date],
        returning="underlying_cause_of_death",
        return_expectations={"category": {"ratios": {"U071":0.2, "C33":0.2, "I60":0.1, "F01":0.1 , "F02":0.05 , "I22":0.05 ,"C34":0.05, "I23":0.25}},},
    ),

    region=patients.registered_practice_as_of(
        "died_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.1,
                    "South West": 0.1,
                },
            },
        },
    ),
)
