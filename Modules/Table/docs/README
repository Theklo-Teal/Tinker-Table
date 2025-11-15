
![](docs/table.mp4)

For Paracortical Initiative, 2025, Diogo "Theklo" Duarte

Other projects:
https://bsky.app/profile/diogo-duarte.bsky.social
https://diogo-duarte.itch.io/
https://github.com/Theklo-Teal


# DESCRIPTION
A Godot node that displays a simple table of data. The header stays visible during scrolling and its column titles can be clicked to sort the rows of the table. Multiple rows can be selected by holding the CTRL key.

# INSTALLATION
This isn't technically a Godot Plugin, it doesn't use the special Plugin features of the Editor, so don't put it inside the "plugin" folder. The folder of the tool can be anywhere else you want, though, but I suggest having it in a "modules" folder.

After that, the «class_name Table» registers the node so you can add it to a project like you add any Godot node.

# USAGE
Firstly you have to set the «columns» array variable with titles of each desire column. Then you can use `add_row()` or `add_dict_row()` to add data to the table. You may also identify each row with an arbitrary unique id using `set_row_id()`.
When sorting the rows, it searches `Variant` values in for comparison in the cells' metadata. Use `set_cell_meta()` to define those values, otherwise it defaults to using the text of the cells.
Multiple functions exist to get details about rows or cells, even metadata specific to the rows. Call `get_selected_rows()` to get the rows which are selected.


# FUTURE IMPROVEMENTS
- Implement signals for when actions happen on the table.
- Allow to sort the table by code.
- Make it possible to re-order the columns.
- Allow different kinds of Control nodes, not just `Label` to be used as cell elements.
- Have an column that's automatically filled with row ids.
- Toggle mode selection
