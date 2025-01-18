import pandas as pd
import numpy as np
import fastavro

# Task 6.1
employee_df = pd.read_csv('source_files/employees.csv')
# print(employee_df.head())
sales_df = pd.read_csv('source_files/sales.csv')
# print(sales_df.head())
houses_df = pd.read_csv('source_files/houses.csv')
# print(houses_df.head())
# print(employee_df.shape)
# print(employee_df.columns)
# print(employee_df.info)

# Task 6.2
emp_names = employee_df.loc[3:10, ['EMP_FIRST_NAME', 'EMP_LAST_NAME']]
# print(emp_names)

# Task 6.3
amount_by_gender = employee_df.value_counts('EMP_GENDER')
# print(amount_by_gender)

# Task 6.4
null_houses = houses_df['SQUARE'].isna()
# print(houses_df[houses_df['SQUARE'].isna()])
fill_nulls = houses_df['SQUARE'].fillna(0, inplace=True)

# Task 6.5
houses_df['UNIT_PRICE'] = houses_df['SQUARE'] * houses_df['PRICE']
# print(houses_df.head())

# Task 6.6
sorted_houses_df = houses_df.sort_values(by='PRICE', ascending=False)
sorted_houses_df.to_json('sorted_house_by_price.json', orient='records', lines=True)

# Task 6.7
women_vera = employee_df[(employee_df['EMP_FIRST_NAME'] == 'Vera') & (employee_df['EMP_GENDER'] == 'F')]
women_vera_count = women_vera.shape[0]
# print(women_vera_count)
# print(women_vera)

# Task 6.8
filtered_houses = houses_df[houses_df['SQUARE'] >= 100]
grouped_houses = filtered_houses.groupby(['HOUSE_CATEGORY_ID', 'HOUSE_SUBCATEGORY_ID']).agg({'SQUARE': 'count'})
# print(grouped_houses)

# Task 6.9
avro_text = [{'NAME': 'Vera', 'GENDER': 'F', 'COUNT_OF_VERA': women_vera_count}]
schema = {
    'type': 'record',
    'name': 'TASK 6.9',
    'fields': [
        {'name': 'NAME', 'type': 'string'},
        {'name': 'GENDER', 'type': 'string'},
        {'name': 'COUNT_OF_VERA', 'type': 'int'}
    ]
}

with open('task6.9.avro', 'wb') as vera_count_file:
    fastavro.writer(vera_count_file, schema, avro_text)

# Task 6.10
sales_amount_avg = sales_df['SALEAMOUNT'].mean()
sales_df['SALEAMOUNT'] = sales_df['SALEAMOUNT'].apply(lambda x: x + sales_amount_avg*0.2)
# print(sales_df.head())

# Task 6.11
unsold_houses = houses_df[~houses_df['HOUSE_ID'].isin(sales_df['HOUSE_ID'])]
unsold_houses['HOUSE_ID'].to_json('output_files/task_11.json', orient='records', lines=True)

house_ids_available = unsold_houses['HOUSE_NAME'].unique().tolist()

# print(house_ids_available)
