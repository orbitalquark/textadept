-- Copyright 2020-2024 Mitchell. See LICENSE.

function test_view_fold_properties()
	view.property['fold.scintillua.compact'] = '0'
	assert(not view.fold_compact, 'view.fold_compact not updated')
	view.fold_compact = true
	assert(view.fold_compact, 'view.fold_compact not updated')
	assert_equal(view.property['fold.scintillua.compact'], '1')
	view.fold_compact = nil
	assert(not view.fold_compact)
	assert_equal(view.property['fold.scintillua.compact'], '0')
	local truthy, falsy = {true, '1', 1}, {false, '0', 0}
	for i = 1, #truthy do
		view.fold_compact = truthy[i]
		assert(view.fold_compact, 'view.fold_compact not updated for "%s"', tostring(truthy[i]))
		view.fold_compact = falsy[i]
		assert(not view.fold_compact, 'view.fold_compact not updated for "%s"', tostring(falsy[i]))
	end
	-- Verify fold and folding properties are synchronized.
	view.fold_compact = true
	assert_equal(view.property['fold.scintillua.compact'], '1')
	view.fold_compact = nil
	assert_equal(view.property['fold.scintillua.compact'], '0')
	view.property['fold'] = '0'
	assert(not view.folding)
	view.folding = true
	assert_equal(view.property['fold'], '1')
end
expected_failure(test_view_fold_properties)
