import 'package:flutter/material.dart';

import 'files_menu.dart';

/// App bar for the Files view with search and menu.
class FilesAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onMenuAction;
  final VoidCallback? onSortTap;

  const FilesAppBar({
    required this.onSearch,
    required this.onMenuAction,
    this.onSortTap,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<FilesAppBar> createState() => _FilesAppBarState();
}

class _FilesAppBarState extends State<FilesAppBar> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  widget.onSearch('');
                });
              },
            )
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showMenu(context),
            ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search transcriptions...',
                border: InputBorder.none,
              ),
              onChanged: widget.onSearch,
            )
          : const Text('Files'),
      actions: [
        if (!_isSearching && widget.onSortTap != null)
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: widget.onSortTap,
          ),
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            if (_isSearching) {
              _searchController.clear();
              widget.onSearch('');
            }
            setState(() => _isSearching = !_isSearching);
          },
        ),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilesMenu(
        onAction: widget.onMenuAction,
      ),
    );
  }
}
