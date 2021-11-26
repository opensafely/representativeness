from cohortextractor import patients
from codelists import *
from config import index_date

demographic_variables = dict(
    age=patients.age_as_of(
        index_date,
        return_expectations={
            "rate" : "universal",
            "int" : {"distribution" : "population_ages"}
        }
    ),

    age_group=patients.categorised_as(
        {
            "0-4": "age < 5",
            "5-9": "age >= 5 AND age < 10",
            "10-14": "age >= 10 AND age < 15",
            "15-19": "age >= 15 AND age < 20",
            "20-24": "age >= 20 AND age < 25",
            "25-29": "age >= 25 AND age < 30",
            "30-34": "age >= 30 AND age < 35",
            "35-39": "age >= 35 AND age < 40",
            "40-44": "age >= 40 AND age < 45",
            "45-49": "age >= 45 AND age < 50",
            "50-54": "age >= 50 AND age < 55",
            "55-59": "age >= 55 AND age < 60",
            "60-64": "age >= 60 AND age < 65",
            "65-69": "age >= 65 AND age < 70",           
            "70-74": "age >= 70 AND age < 75",
            "75-79": "age >= 75 AND age < 80",
            "80-84": "age >= 80 AND age < 85",
            "85-89": "age >= 85 AND age < 90",
            "90+": "age >= 90",
            "missing": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0-4": 0.05,
                    "5-9": 0.05,
                    "10-14": 0.05,
                    "15-19": 0.05,
                    "20-24": 0.05,
                    "25-29": 0.05,
                    "30-34": 0.05,
                    "35-39": 0.05,
                    "40-44": 0.1,
                    "45-49": 0.05,
                    "50-54": 0.05,
                    "55-59": 0.05,
                    "60-64": 0.05,
                    "65-69": 0.05,           
                    "70-74": 0.05,
                    "75-79": 0.05,
                    "80-84": 0.05,
                    "85-89": 0.05,
                    "90+": 0.05,
                }
            },
        },
    ),

    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.48, "F": 0.50,"U":0.01,"I":0.01}},
        }
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

 imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation < 32844""",
        },
        index_of_multiple_deprivation=patients.address_as_of(
            index_date,
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                }
            },
        },
    ),

    ethnicity = patients.categorised_as(
            {"0": "DEFAULT",
            "1": "eth='1' OR (NOT eth AND ethnicity_sus='1')", 
            "2": "eth='2' OR (NOT eth AND ethnicity_sus='2')", 
            "3": "eth='3' OR (NOT eth AND ethnicity_sus='3')", 
            "4": "eth='4' OR (NOT eth AND ethnicity_sus='4')",  
            "5": "eth='5' OR (NOT eth AND ethnicity_sus='5')",
            }, 
            return_expectations={
            "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
            "incidence": 0.4,
            },
        
        eth=patients.with_these_clinical_events(    
            ethnicity_codes,
            returning="category",
            find_last_match_in_period=True,
            include_date_of_match=False,
            return_expectations={
                "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                "incidence": 0.75,
            },
        ),

    # fill missing ethnicity from SUS
        ethnicity_sus=patients.with_ethnicity_from_sus(
            returning="group_6",  
            use_most_frequent_code=True,
            return_expectations={
                "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                "incidence": 0.4,
            },
        ),
    ),
    ethnicity_16=patients.categorised_as(
            {"0": "DEFAULT",
            "1": "eth16='1' OR (NOT eth16 AND ethnicity_sus16='1')", 
            "2": "eth16='2' OR (NOT eth16 AND ethnicity_sus16='2')", 
            "3": "eth16='3' OR (NOT eth16 AND ethnicity_sus16='3')", 
            "4": "eth16='4' OR (NOT eth16 AND ethnicity_sus16='4')",  
            "5": "eth16='5' OR (NOT eth16 AND ethnicity_sus16='5')",
            "6": "eth16='6' OR (NOT eth16 AND ethnicity_sus16='6')",
            "7": "eth16='7' OR (NOT eth16 AND ethnicity_sus16='7')",
            "8": "eth16='8' OR (NOT eth16 AND ethnicity_sus16='8')",
            "9": "eth16='9' OR (NOT eth16 AND ethnicity_sus16='9')",
            "10": "eth16='10' OR (NOT eth16 AND ethnicity_sus16='10')",
            "11": "eth16='11' OR (NOT eth16 AND ethnicity_sus16='11')",
            "12": "eth16='12' OR (NOT eth16 AND ethnicity_sus16='12')",
            "13": "eth16='13' OR (NOT eth16 AND ethnicity_sus16='13')",
            "14": "eth16='14' OR (NOT eth16 AND ethnicity_sus16='14')",
            "15": "eth16='15' OR (NOT eth16 AND ethnicity_sus16='15')",
            "16": "eth16='16' OR (NOT eth16 AND ethnicity_sus16='16')",
            }, 
                return_expectations={
                        "category": {
                            "ratios": {
                                "1": 0.0625,
                                "2": 0.0625,
                                "3": 0.0625,
                                "4": 0.0625,
                                "5": 0.0625,
                                "6": 0.0625,
                                "7": 0.0625,
                                "8": 0.0625,
                                "9": 0.0625,
                                "10": 0.0625,
                                "11": 0.0625,
                                "12": 0.0625,
                                "13": 0.0625,
                                "14": 0.0625,
                                "15": 0.0625,
                                "16": 0.0625,
                            }
                        },
                        "incidence": 0.75,
                    },
            eth16=patients.with_these_clinical_events(
                ethnicity_codes_16,
                returning="category",
                find_last_match_in_period=True,
                include_date_of_match=True,
                return_expectations={
                    "category": {
                        "ratios": {
                            "1": 0.0625,
                            "2": 0.0625,
                            "3": 0.0625,
                            "4": 0.0625,
                            "5": 0.0625,
                            "6": 0.0625,
                            "7": 0.0625,
                            "8": 0.0625,
                            "9": 0.0625,
                            "10": 0.0625,
                            "11": 0.0625,
                            "12": 0.0625,
                            "13": 0.0625,
                            "14": 0.0625,
                            "15": 0.0625,
                            "16": 0.0625,
                        }
                    },
                    "incidence": 0.75,
                },
            ),
            ethnicity_sus16=patients.with_ethnicity_from_sus(
                returning="group_16",  
                use_most_frequent_code=True,
                return_expectations={
                    "category": {
                        "ratios": {
                            "1": 0.0625,
                            "2": 0.0625,
                            "3": 0.0625,
                            "4": 0.0625,
                            "5": 0.0625,
                            "6": 0.0625,
                            "7": 0.0625,
                            "8": 0.0625,
                            "9": 0.0625,
                            "10": 0.0625,
                            "11": 0.0625,
                            "12": 0.0625,
                            "13": 0.0625,
                            "14": 0.0625,
                            "15": 0.0625,
                            "16": 0.0625,
                        }
                    },
                    "incidence": 0.75,
                },
            ),
    ),
)