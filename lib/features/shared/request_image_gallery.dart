import 'package:flutter/material.dart';

class RequestImageGallery extends StatelessWidget {
  const RequestImageGallery({
    super.key,
    required this.imageUrls,
    this.title = 'Imágenes adjuntas',
  });

  final List<String> imageUrls;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      insetPadding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: InteractiveViewer(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 280,
                              height: 280,
                              child: Center(
                                child: Text('No fue posible cargar la imagen.'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 132,
                    color: const Color(0xFFF1F6F3),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Imagen no disponible',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}