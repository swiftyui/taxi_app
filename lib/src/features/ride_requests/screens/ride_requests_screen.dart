import 'package:TaxiApp/src/core/models/ride_request.dart';
import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RideRequestsScreen extends StatelessWidget {
  RideRequestsScreen({super.key});

  final RideRequestsProvider _provider = RideRequestsProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Ride requests',
      subtitle: 'Your rides and incoming requests',
    ),
    body: Obx(() {
      if ((_provider.isLoadingRequests.value ||
              _provider.isLoadingMyRequests.value) &&
          _provider.driverRequests.isEmpty &&
          _provider.myRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_provider.driverRequests.isEmpty && _provider.myRequests.isEmpty) {
        return const _EmptyRideRequests();
      }
      return RefreshIndicator(
        onRefresh: () async {
          await _provider.refreshMyRequests();
          if (_provider.isDriver) {
            await _provider.refreshDriverRequests();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            const _RequestSectionTitle(
              title: 'My ride requests',
              subtitle: 'Manage rides you have requested.',
            ),
            const SizedBox(height: 8),
            if (_provider.myRequests.isEmpty)
              const _InlineEmpty(message: 'You have not requested a ride yet.')
            else
              for (final request in _provider.myRequests) ...[
                _RideRequestCard(
                  request: request,
                  onExpire: request.isRequested
                      ? () => _expireRequest(context, request)
                      : null,
                  onDelete: () => _deleteRequest(context, request),
                ),
                const SizedBox(height: 8),
              ],
            if (_provider.isDriver) ...[
              const SizedBox(height: 14),
              const _RequestSectionTitle(
                title: 'Incoming requests',
                subtitle: 'Active requests from HambaGo riders.',
              ),
              const SizedBox(height: 8),
              if (_provider.driverRequests.isEmpty)
                const _InlineEmpty(message: 'No riders need a ride right now.')
              else
                for (final request in _provider.driverRequests) ...[
                  _RideRequestCard(request: request),
                  const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      );
    }),
  );

  Future<void> _expireRequest(BuildContext context, RideRequest request) async {
    final confirmed = await _confirm(
      context,
      title: 'Expire request?',
      message:
          'Drivers will no longer see this as an active ride request. '
          'It will remain in your history.',
      action: 'Expire',
    );
    if (confirmed) {
      await _provider.expireRequest(request.id);
    }
  }

  Future<void> _deleteRequest(BuildContext context, RideRequest request) async {
    final confirmed = await _confirm(
      context,
      title: 'Delete request?',
      message: 'This ride request will be permanently removed.',
      action: 'Delete',
    );
    if (confirmed) {
      await _provider.deleteRequest(request.id);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

class _RideRequestCard extends StatelessWidget {
  const _RideRequestCard({required this.request, this.onExpire, this.onDelete});

  final RideRequest request;
  final VoidCallback? onExpire;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE6F1F5),
            child: Icon(
              Icons.person_pin_circle_rounded,
              color: Colours.blueThree,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.riderName,
                  style: const TextStyle(
                    color: Colours.primaryOne,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${request.originName} → ${request.destinationName}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '${request.associationName} · '
                  'R${request.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colours.charcoalLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colours.blueThree,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.requestedAt == null
                          ? 'Just now'
                          : DateFormat(
                              'd MMM · HH:mm',
                            ).format(request.requestedAt!.toLocal()),
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (request.isExpired)
                      const _StatusPill(label: 'Expired')
                    else
                      const _StatusPill(label: 'Active', active: true),
                  ],
                ),
                if (onExpire != null || onDelete != null) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onExpire != null)
                        TextButton.icon(
                          onPressed: onExpire,
                          icon: const Icon(Icons.timer_off_outlined, size: 17),
                          label: const Text('Expire'),
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 17),
                          label: const Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RequestSectionTitle extends StatelessWidget {
  const _RequestSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colours.primaryOne,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        subtitle,
        style: const TextStyle(color: Colours.charcoalLight, fontSize: 11),
      ),
    ],
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colours.containerOne,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colours.charcoalLight,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE5F5ED) : const Color(0xFFF0F1F2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? const Color(0xFF227447) : Colours.charcoalLight,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmptyRideRequests extends StatelessWidget {
  const _EmptyRideRequests();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: Colours.containerOne,
          ),
          SizedBox(height: 12),
          Text(
            'No ride requests yet',
            style: TextStyle(
              color: Colours.primaryOne,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'New requests will remain available here after their alert closes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colours.charcoalLight, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
