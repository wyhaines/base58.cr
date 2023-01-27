# struct Char
#   macro static_array(*nums)
#     %array = uninitialized StaticArray({{@type}}, {{nums.size}})
#     {% for num, i in nums %}
#       %array.to_unsafe[{{i}}] = {{num}}
#     {% end %}
#     %array
#   end
# end
