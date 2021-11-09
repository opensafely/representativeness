# LIBRARIES

# cohort extractor
from cohortextractor import StudyDefinition, patients
from codelists import *
from common_variables import demographic_variables
from config import *
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

    msoa=patients.address_as_of(
        index_date,
        returning="msoa",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"E02000001": 0.0625, "E02000002": 0.0625, "E02000003": 0.0625, "E02000004": 0.0625,
                                    "E02000005": 0.0625, "E02000007": 0.0625, "E02000008": 0.0625, "E02000009": 0.0625, 
                                    "E02000010": 0.0625, "E02000011": 0.0625, "E02000012": 0.0625, "E02000013": 0.0625, 
                                    "E02000014": 0.0625, "E02000015": 0.0625, "E02000016": 0.0625, "E02000017": 0.0625}},
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
        between=[index_date,end_date],
        returning="binary_flag",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest" : index_date},
            "rate" : "exponential_increase"
        },
    ),

    died_cause_ons=patients.died_from_any_cause(
        between=[index_date,end_date],
        returning="underlying_cause_of_death",
        return_expectations={"category": {"ratios": {"U071":0.2, "C33":0.2, "I60":0.1, "F01":0.1 , "F02":0.05 , "I22":0.05 ,"C34":0.05, "I23":0.25}},},
    ),

    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        between=[index_date,end_date],
        match_only_underlying_cause=True,
        return_expectations={
            "date": {"earliest" : "2020-01-01"},
            "rate" : "exponential_increase"
        },
    ),
    **demographic_variables,
)
