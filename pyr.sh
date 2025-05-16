#!/bin/bash

draw_pyramid() {
  local n=$1
  local symbol="o"
  local rows=1
  local stones_left=$n

  # Calculate number of rows needed
  while (( rows * (rows + 1) / 2 < n )); do
    ((rows++))
  done

  stones_drawn=0
  for ((i=1; i<=rows; i++)); do
    stones_this_row=$i
    # On last row, only draw what's left
    if (( stones_left < stones_this_row )); then
      stones_this_row=$stones_left
    fi
    spaces=$((rows - i))
    printf "%*s" "$spaces" ""
    for ((j=1; j<=stones_this_row; j++)); do
      printf "%s " "$symbol"
      ((stones_drawn++))
      ((stones_left--))
      if ((stones_drawn == n)); then break 2; fi
    done
    printf "\n"
  done
  echo "($n stones)"
}

# Test:
for n in 1 3 6 10 15 21; do
  draw_pyramid $n
  echo
done
