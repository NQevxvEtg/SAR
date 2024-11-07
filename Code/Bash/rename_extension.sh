for file in *; do
  if [ -f "$file" ]; then
    mv -- "$file" "${file%.*}.jl"
  fi
done
