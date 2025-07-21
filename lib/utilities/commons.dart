int sumWithFold(List<int> numbers) {
  return numbers.fold(0, (sum, element) => sum + element);
}