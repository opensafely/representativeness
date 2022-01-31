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
    population=patients.all(),

    died_any=patients.died_from_any_cause(
        between=[index_date,end_date_death],
        returning="binary_flag",
        return_expectations={
            "rate" : "exponential_increase",
            "incidence": 0.4,
        },
    ),

    died_cause_ons=patients.died_from_any_cause(
        between=[index_date,end_date_death],
        returning="underlying_cause_of_death",
        return_expectations={"category": {"ratios": {"U071":0.2, "C33":0.2, "I60":0.1, "F01":0.1 , "F02":0.05 , "I22":0.05 ,"C34":0.05, "I23":0.25}},},
    ),

    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        between=[index_date,end_date_death],
        match_only_underlying_cause=True,
        return_expectations={
            "date": {"earliest" : "2020-01-01"},
            "rate" : "exponential_increase"
        },
    ),

    region=patients.registered_practice_as_of(
        index_date,
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
