import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFDF9F4),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      centerTitle: true,
      leadingWidth: 76,
      leading: (showBackButton && (onBack != null || Navigator.canPop(context)))
          ? Padding(
              padding: const EdgeInsets.only(left: 24, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    if (onBack != null) {
                      onBack!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF012D1D),
                    size: 28,
                  ),
                ),
              ),
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: titleWidget ?? Text(
          title ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              )
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
