function aurorax_get_decomposed_color, rgb_triple

    dims = size(rgb_triple, /dimensions)
    if dims ne [3] and dims ne [1,3] then stop, "Please enter color as a 3-element array, [R, G, B]."
    return, rgb_triple[0] + (rgb_triple[1] * 2L^8L) + (rgb_triple[2] * 2L^16L)

end