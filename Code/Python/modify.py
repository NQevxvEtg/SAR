import re


def replace(file, pattern, subst):
    print(file, pattern, subst)
    # Read contents from file as a single string
    file_handle = open(file, 'r')
    file_string = file_handle.read()
    file_handle.close()

    # Use RE package to allow for replacement (also allowing for (multiline) REGEX)
    file_string = (re.sub(pattern, subst, file_string))

    # Write contents to file.
    # Using mode 'w' truncates the file.
    file_handle = open(file, 'w')
    file_handle.write(file_string)
    file_handle.close()


def replaceLineByLine(file, pattern, subst):

    # Read contents from file as a single string
    file_handle = open(file, 'r')
    file_string = file_handle.readlines()
    file_handle.close()


    def lineMod(line, pattern, subst):

        if re.search(pattern, line):
            file_handle.write(subst)
        else:
            file_handle.write(line)

    file_handle = open(file, 'w')

    list(map(lambda line: lineMod(line, pattern, subst), file_string))

    file_handle.close()
