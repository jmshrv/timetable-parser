import argparse
from bs4 import BeautifulSoup, Tag

parser = argparse.ArgumentParser(
    prog="timetable2json",
    description="Parses a University of Nottingham timetable to JSON",
)

parser.add_argument("input", help="The input timetable HTML file")
parser.add_argument("output", help="The JSON output file")

args = parser.parse_args()

file = open(args.input, "r")
soup = BeautifulSoup(file.read(), "html.parser")
file.close()

mon = soup.select_one("body > table:nth-child(3)")

tbody = mon.find("tbody")

row: Tag
for row in tbody.find_all("tr"):
    row_data = row.find_all("td")

    for data in row_data:
        activity = data[0]
        module_title = data[1]
        session_title = data[2]
        type = data[3]
        weeks = data[4]
        day = data[5]
        start = data[6]
        end = data[7]
        staff = data[8]
        location = data[9]
        notes = data[10]
