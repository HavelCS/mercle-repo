import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mercle/common/custom-appbar.dart';
import 'package:mercle/constants/colors.dart';

class MkeyScreen extends StatefulWidget {
  const MkeyScreen({super.key});

  @override
  State<MkeyScreen> createState() => _MkeyScreenState();
}

class _MkeyScreenState extends State<MkeyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          CustomAppBar(),

          SizedBox(height: 20.h),
          Divider(height: 1, color: Color(0xff888888)),
          SizedBox(height: 50.h),
          Text(
            'Your mKey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 44.sp,
              fontFamily: 'HandjetRegular',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Tap the device to scan a mKey QR\ncode and prove your humanity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6C6C6C),
              fontSize: 16.sp,
              fontFamily: 'GeistRegular',
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: -0.16,
            ),
          ),
          SizedBox(height: 19.h),
          Container(height: 358.h),
          SizedBox(height: 20.h),
          InkWell(
            onTap: () {},
            child: Column(
              children: [
                Text(
                  'Humanity Score',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontFamily: 'GeistRegular',
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                    letterSpacing: -0.16,
                  ),
                ),
                Text(
                  '70 / 100',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontFamily: 'HandjetRegular',
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                    letterSpacing: -0.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
