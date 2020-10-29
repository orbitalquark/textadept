function foo(i)
  print('foo', i)
end

print('start')
for i = 1, 4 do
  foo(i)
end
print('end')
