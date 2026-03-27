import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kakikaki/core/extension/context_extension.dart';

class SocialSignInButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isAnyLoading;
  final double? iconWidth;

  const SocialSignInButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    required this.isLoading,
    required this.isAnyLoading,
    this.iconWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        // 어떤 버튼이라도 로딩 중이면 모든 버튼 비활성화
        onPressed: isAnyLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor, disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          // 비활성화 시에도 배경색 유지하고 싶다면 disabledBackgroundColor 설정 가능
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(iconPath, width: iconWidth),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      style: context.h5_600Style.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
