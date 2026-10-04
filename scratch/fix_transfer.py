import re

path = 'lib/features/payments/presentation/screens/transfer_capture_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Remove the platform chip row (Nequi/Daviplata/Otro)
c = re.sub(
    r'\s*const SizedBox\(height: AppDimensions\.space16\),\s*// .* Plataforma.*?\.toList\(\),\s*\),\s*const SizedBox\(height: AppDimensions\.space24\),',
    '\n                    const SizedBox(height: AppDimensions.space24),',
    c,
    flags=re.DOTALL
)

# Update the label
c = c.replace(
    "'Comprobante por ${billSubtotal.toCop}'",
    "'Comprobante de Transferencia · ${billSubtotal.toCop}'"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('Done')
