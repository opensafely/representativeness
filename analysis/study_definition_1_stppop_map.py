# LIBRARIES

# cohort extractor
from cohortextractor import StudyDefinition, patients
# dictionary of STP codes (for dummy data)
from dictionaries import dict_stp
from codelists import *
from common_variables import demographic_variables
from config import index_date
# set the index date
# STUDY POPULATION

study = StudyDefinition(
    index_date=index_date,
    default_expectations={
        "date": {
            "earliest": index_date,
            "latest": "today",
        },  # date range for simulated dates
        "rate": "uniform",
        "incidence": 1,
    },
    # This line defines the study population
    population=patients.registered_as_of(index_date),
    # this line defines the stp variable we want to extract
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "category": {"ratios": dict_stp},
        },
    ),
    nuts1=patients.registered_practice_as_of(
        "index_date",
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
    practice_id=patients.registered_practice_as_of(
        "index_date",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
            "incidence": 1,
        },
    ),

    died_any=patients.died_from_any_cause(
        between=["2020-01-01","2020-12-31"],
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest" : "2020-01-01"},
            "rate" : "exponential_increase"
        },
    ),

    died_cause_ons=patients.died_from_any_cause(
        between=["2020-01-01","2020-12-31"],
        returning="underlying_cause_of_death",
        return_expectations={"category": {"ratios": {"U071":0.2, "I21":0.2, "C34":0.1, "C83":0.1 , "J09":0.05 , "J45.1":0.05 ,"G30":0.05, "A01.2":0.25}},},
    ),

    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        between=["2020-01-01","2020-12-31"],
        match_only_underlying_cause=True,
        return_expectations={
            "date": {"earliest" : "2020-01-01"},
            "rate" : "exponential_increase"
        },
    ),

    died_ons_cancer_flag_any=patients.with_these_codes_on_death_certificate(
        cancer_death_codelist,
        between=["2020-01-01","2020-12-31"],
        match_only_underlying_cause=True,
        return_expectations={
            "date": {"earliest" : "2020-01-01"},
            "rate" : "exponential_increase"
        },
    ),
    
    **demographic_variables,
)