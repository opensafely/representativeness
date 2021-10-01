from cohortextractor import (
    codelist,
    codelist_from_csv,
)

# measurement codes

ethnicity_codes = codelist_from_csv(
        "codelists/opensafely-ethnicity.csv",
        system="ctv3",
        column="Code",
        category_column="Grouping_6",
)

covid_codelist = codelist(["U071", "U072"], system="icd10")

cancer_death_codelist = codelist_from_csv(
    "codelists/user-anna-schultze-cancer.csv",
    system="icd10",
    column="code",
)

