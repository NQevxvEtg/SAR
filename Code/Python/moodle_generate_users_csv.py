import pandas as pd

path = r'C:\\Users\\username\\'

filename = 'file.txt'

df = pd.read_csv(path + filename, header=None)

df.rename(columns={0: 'username'}, inplace=True)

df['password']='password'

df[["firstname", "lastname"]] = df["username"].str.split('.',expand=True)
df["firstname"] = df["firstname"].str.capitalize()
df["lastname"] = df["lastname"].str.capitalize()

df['email']=df["username"]+'@domain'

df['course1']='course_name'

df['role1']='student'

df.to_csv(path+'studentlist.' + filename + '.csv',index=False)


print(df.to_string()) 

