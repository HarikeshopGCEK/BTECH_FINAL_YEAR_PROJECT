from pathlib import Path
import csv
from datetime import datetime, timedelta
import textwrap

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.patches import Patch

folder = Path(__file__).parent
with (folder / "battery-project-schedule.csv").open(newline="") as schedule:
    tasks = list(csv.DictReader(schedule))

colors = {
    "Planning": "#4338a5",
    "Design": "#2563b9",
    "Development": "#008b91",
    "Milestone": "#d38a13",
    "Validation": "#ae4880",
    "Delivery": "#477a39",
}
plt.rcParams.update({"font.family": "DejaVu Sans", "pdf.fonttype": 42})
figure, axis = plt.subplots(figsize=(13.8, 8.1))
figure.subplots_adjust(left=0.455, right=0.985, top=0.925, bottom=0.075)
start_limit = datetime(2026, 9, 1)
end_limit = datetime(2027, 5, 1)
axis.set_xlim(start_limit, end_limit)
axis.set_ylim(len(tasks) - 0.5, -0.5)

for index, task in enumerate(tasks):
    start = datetime.fromisoformat(task["Start"])
    finish = datetime.fromisoformat(task["Finish"])
    if index % 2 == 0:
        axis.axhspan(index - 0.5, index + 0.5, color="#f1f4fa", zorder=0)
    axis.axhline(index + 0.5, color="#e1e5ed", linewidth=0.45, zorder=1)
    if task["Phase"] == "Milestone":
        axis.scatter(start, index, marker="D", s=75,
                     color=colors[task["Phase"]], zorder=4)
    else:
        axis.barh(index, (finish - start).days + 1, left=mdates.date2num(start),
                  height=0.55, color=colors[task["Phase"]], zorder=3)
    label = "\n".join(textwrap.wrap(task["Task"], width=44))
    axis.text(-0.815, index, f"{index + 1:02d}",
              transform=axis.get_yaxis_transform(), va="center", ha="left",
              fontsize=10.5, color="#737b8c")
    axis.text(-0.75, index, label,
              transform=axis.get_yaxis_transform(), va="center", ha="left",
              fontsize=10.2, linespacing=1.15, color="#202d43")

axis.set_yticks([])
axis.xaxis.set_major_locator(mdates.MonthLocator())
axis.xaxis.set_major_formatter(mdates.DateFormatter(""))
axis.grid(axis="x", color="#cdd4e0", linewidth=0.7, zorder=1)
axis.tick_params(axis="x", length=0)
for month_index in range(8):
    year = 2026 if month_index < 4 else 2027
    month = month_index + 9 if month_index < 4 else month_index - 3
    month_start = datetime(year, month, 1)
    next_month = datetime(year + (month == 12), month % 12 + 1, 1)
    middle = month_start + (next_month - month_start) / 2
    axis.text(mdates.date2num(middle), 1.022, middle.strftime("%b\n%Y"),
              transform=axis.get_xaxis_transform(), ha="center", va="bottom",
              fontsize=11, fontweight="bold", color="#30348f")
axis.text(-0.815, 1.022, "NO.", transform=axis.transAxes,
          fontsize=10.5, fontweight="bold", color="#30348f")
axis.text(-0.75, 1.022, "PROJECT ACTIVITY", transform=axis.transAxes,
          fontsize=11, fontweight="bold", color="#30348f")
for spine in axis.spines.values():
    spine.set_visible(False)
legend_items = [Patch(facecolor=color, label=phase)
                for phase, color in colors.items()]
figure.legend(handles=legend_items, loc="lower center", ncol=6,
              frameon=False, fontsize=10, bbox_to_anchor=(0.5, 0.005))
figure.savefig(folder / "battery-project-gantt.pdf", facecolor="white")
plt.close(figure)