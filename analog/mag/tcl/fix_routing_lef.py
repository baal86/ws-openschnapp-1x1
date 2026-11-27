#!/usr/bin/env python3
import re
import sys
from pathlib import Path
import klayout.db as db

# Strictly Metal2 only (GF180MCU GDS layer 36/0)
METAL2_GDS_LAYER = (36, 0)

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 fix_routing_lef.py <input.mag.gds> <target.mag.lef> [origin_x] [origin_y]")
        sys.exit(1)

    gds_path = Path(sys.argv[1])
    lef_path = Path(sys.argv[2])
    orig_x = float(sys.argv[3]) if len(sys.argv) > 3 else -442.400
    orig_y = float(sys.argv[4]) if len(sys.argv) > 4 else -442.960

    # 1. Extract only Metal2 (36/0) wire geometries from GDS
    ly = db.Layout()
    ly.read(str(gds_path))
    top = ly.top_cell()

    rects = []
    for li in ly.layer_indices():
        info = ly.get_info(li)
        if (info.layer, info.datatype) != METAL2_GDS_LAYER:
            continue
        for s in top.shapes(li).each():
            if s.is_box() or s.is_polygon() or s.is_path():
                b = s.dbbox()
                rects.append((b.left, b.bottom, b.right, b.top))

    # 2. Build the Metal2-only OBS block
    obs_lines = ["  OBS", "      LAYER Metal2 ;"]
    for x1, y1, x2, y2 in rects:
        obs_lines.append(f"        RECT {x1:.3f} {y1:.3f} {x2:.3f} {y2:.3f} ;")
    obs_lines.append("  END")
    new_obs_block = "\n".join(obs_lines)

    # 3. Rewrite existing LEF or create a new one
    macro_name = gds_path.name.split(".")[0]
    if lef_path.exists():
        text = lef_path.read_text()
        text = re.sub(r"\bCLASS\s+\w+\s*;", "CLASS COVER ;", text)
        text = re.sub(r"\bORIGIN\s+[-\d.]+\s+[-\d.]+\s*;", f"ORIGIN {orig_x:.3f} {orig_y:.3f} ;", text)
        text = re.sub(r"\bSIZE\s+[-\d.]+\s+BY\s+[-\d.]+\s*;", "SIZE 1.000 BY 1.000 ;", text)

        if re.search(r"^\s*OBS\b.*?^\s*END\b", text, flags=re.DOTALL | re.MULTILINE):
            text = re.sub(r"^\s*OBS\b.*?^\s*END\b", new_obs_block, text, flags=re.DOTALL | re.MULTILINE)
        else:
            text = re.sub(rf"(END\s+{re.escape(macro_name)}\b)", f"{new_obs_block}\n\\1", text)
    else:
        text = (
            f"VERSION 5.7 ;\n"
            f"  NOWIREEXTENSIONATPIN ON ;\n"
            f"  DIVIDERCHAR \"/\" ;\n"
            f"  BUSBITCHARS \"[]\" ;\n"
            f"MACRO {macro_name}\n"
            f"  CLASS COVER ;\n"
            f"  FOREIGN {macro_name} 0.000 0.000 ;\n"
            f"  ORIGIN {orig_x:.3f} {orig_y:.3f} ;\n"
            f"  SIZE 1.000 BY 1.000 ;\n"
            f"{new_obs_block}\n"
            f"END {macro_name}\n"
            f"END LIBRARY\n"
        )

    lef_path.write_text(text)
    print(f"Updated {lef_path} with {len(rects)} Metal2 OBS rects from {gds_path}")

if __name__ == "__main__":
    main()
