import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_featured_products_usecase.dart';
import '../../domain/usecases/get_new_arrivals_usecase.dart';
import '../../domain/usecases/get_on_sale_products_usecase.dart';
import '../../domain/usecases/get_product_list_usecase.dart';

part 'product_list_event.dart';
part 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc({
    required GetProductListUseCase getProductListUseCase,
    required GetFeaturedProductsUseCase getFeaturedProductsUseCase,
    required GetNewArrivalsUseCase getNewArrivalsUseCase,
    required GetOnSaleProductsUseCase getOnSaleProductsUseCase,
  })  : _getProductListUseCase = getProductListUseCase,
        _getFeaturedProductsUseCase = getFeaturedProductsUseCase,
        _getNewArrivalsUseCase = getNewArrivalsUseCase,
        _getOnSaleProductsUseCase = getOnSaleProductsUseCase,
        super(const ProductListInitial()) {
    on<ProductListLoadRequested>(_onLoadList);
    on<ProductListLoadFeatured>(_onLoadFeatured);
    on<ProductListLoadNewArrivals>(_onLoadNewArrivals);
    on<ProductListLoadOnSale>(_onLoadOnSale);
    on<ProductListLoadHomeSections>(_onLoadHomeSections);
  }

  final GetProductListUseCase _getProductListUseCase;
  final GetFeaturedProductsUseCase _getFeaturedProductsUseCase;
  final GetNewArrivalsUseCase _getNewArrivalsUseCase;
  final GetOnSaleProductsUseCase _getOnSaleProductsUseCase;

  Future<void> _onLoadList(
    ProductListLoadRequested event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final result = await _getProductListUseCase(
        limit: event.limit,
        skip: event.skip,
        category: event.category,
        gender: event.gender,
        onSale: event.onSale,
        featured: event.featured,
        gift: event.gift,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        sort: event.sort,
        search: event.search,
      );
      emit(ProductListLoaded(
        products: result.products,
        total: result.total,
        limit: result.limit,
        skip: result.skip,
      ));
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }

  Future<void> _onLoadFeatured(
    ProductListLoadFeatured event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final list = await _getFeaturedProductsUseCase(limit: event.limit);
      emit(ProductListLoaded(
        products: list,
        total: list.length,
        limit: event.limit,
        skip: 0,
      ));
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }

  Future<void> _onLoadNewArrivals(
    ProductListLoadNewArrivals event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final list = await _getNewArrivalsUseCase(limit: event.limit);
      emit(ProductListLoaded(
        products: list,
        total: list.length,
        limit: event.limit,
        skip: 0,
      ));
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }

  Future<void> _onLoadOnSale(
    ProductListLoadOnSale event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final list = await _getOnSaleProductsUseCase(limit: event.limit);
      emit(ProductListLoaded(
        products: list,
        total: list.length,
        limit: event.limit,
        skip: 0,
      ));
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }

  Future<void> _onLoadHomeSections(
    ProductListLoadHomeSections event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListHomeLoading());
    try {
      final results = await Future.wait([
        _getFeaturedProductsUseCase(limit: event.limit),
        _getNewArrivalsUseCase(limit: event.limit),
        _getOnSaleProductsUseCase(limit: event.limit),
      ]);
      emit(ProductListHomeLoaded(
        featured: results[0],
        newArrivals: results[1],
        sale: results[2],
      ));
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }
}
