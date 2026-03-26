import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class PublicListItem extends StatelessWidget {
  const PublicListItem({
    super.key,
    required this.title,
    this.subTitle = "",
    this.description = "",
  });
  final String title;
  final String? subTitle;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(left: 15, top: 10),
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: context.palette.shadow.withExactOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toString(),
                      style: context.h6_400Style
                          .copyWith(color: context.palette.onSurface)),
                  const SizedBox(width: 10),
                  Text(subTitle.toString(),
                      style: context.h6_400Style
                          .copyWith(color: context.palette.onSurface)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(description.toString(),
                      style: context.h6_400Style
                          .copyWith(color: context.palette.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
