import os
import sys


def convert_to_seconds(time):  # just handle the seconds
    time = time.strip()
    if str(time).strip() == "None":
        print("None")
        return None

    time = time.split('.')[1]
    time = time.replace('s', '')

    return float(time) / 1000


file_name = sys.argv[1]

r, u, s = 0, 0, 0

for i in range(10):
    with open(file_name.split(".txt")[0] + "_{}.txt".format(i+1), 'r') as f:
        data = f.readlines()
        print(data)
        # data.strip()
        print(data[1].strip().split('\t')[1])
        real = data[1].strip().replace('\n', '')
        user = data[2].strip().split('\t')[1].replace('\n', '')
        sys = data[3].strip().split('\t')[1].replace('\n', '')

        r += convert_to_seconds(real)
        u += convert_to_seconds(user)
        s += convert_to_seconds(sys)

        os.system("rm " + file_name.split(".txt")[0] + "_{}.txt".format(i+1))

r /= 10
u /= 10
s /= 10

r = round(r, 3)
u = round(u, 3)
s = round(s, 3)


# create a new file
with open(file_name, 'w') as f:
    f.write("Real: {}\n".format(r))
    f.write("User: {}\n".format(u))
    f.write("Sys: {}\n".format(s))


os.system('cat ' + file_name)
