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
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "E54000005": 0.04,
                    "E54000006": 0.04,
                    "E54000007": 0.04,
                    "E54000008": 0.04,
                    "E54000009": 0.04,
                    "E54000010": 0.04,
                    "E54000012": 0.04,
                    "E54000013": 0.03,
                    "E54000014": 0.03,
                    "E54000015": 0.03,
                    "E54000016": 0.03,
                    "E54000017": 0.03,
                    "E54000020": 0.03,
                    "E54000021": 0.03,
                    "E54000022": 0.03,
                    "E54000023": 0.03,
                    "E54000024": 0.03,
                    "E54000025": 0.03,
                    "E54000026": 0.03,
                    "E54000027": 0.03,
                    "E54000029": 0.03,
                    "E54000033": 0.03,
                    "E54000035": 0.03,
                    "E54000036": 0.03,
                    "E54000037": 0.03,
                    "E54000040": 0.03,
                    "E54000041": 0.03,
                    "E54000042": 0.03,
                    "E54000044": 0.03,
                    "E54000043": 0.03,
                    "E54000049": 0.03,
                }
            },
        },
    ),
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

    **demographic_variables,
)
