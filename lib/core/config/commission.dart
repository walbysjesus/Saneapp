/// ComisiÃ³n de SaneApp para cada transacciÃ³n
const double saneAppCommissionPercent = 0.10;

/// Calcula la comisiÃ³n de SaneApp a partir del monto total
int calculateSaneAppCommission(int totalAmount) {
  return (totalAmount * saneAppCommissionPercent).round();
}

/// Calcula el monto a transferir al proveedor despuÃ©s de la comisiÃ³n
int calculateProviderPayout(int totalAmount) {
  return totalAmount - calculateSaneAppCommission(totalAmount);
}

