@extends('layout.with-main')

@section('breadcrumbs')
    <li class="breadcrumbV2">
        <a href="{{ route('staff.dashboard.index') }}" class="breadcrumb__link">
            {{ __('staff.staff-dashboard') }}
        </a>
    </li>
    <li class="breadcrumb--active">Solicitudes de cambio de nombre de usuario</li>
@endsection

@section('page', 'page__staff-username-changes--index')

@section('main')
    <section class="panelV2">
        <header class="panel__header">
            <h2 class="panel__heading">Solicitudes de cambio de nombre de usuario</h2>
        </header>
        <div class="data-table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Usuario</th>
                        <th>Nombre actual</th>
                        <th>Nuevo nombre</th>
                        <th>Estado</th>
                        <th>Fecha de solicitud</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($usernameChanges as $change)
                        <tr>
                            <td>{{ $change->id }}</td>
                            <td>
                                <a href="{{ route('users.show', ['user' => $change->user]) }}">
                                    {{ $change->user->username }}
                                </a>
                            </td>
                            <td>{{ $change->old_username ?? $change->user->username }}</td>
                            <td>{{ $change->new_username ?? 'No especificado aún' }}</td>
                            <td>
                                @if ($change->status === 'Pending')
                                    <span class="text-warning">Pendiente</span>
                                @elseif ($change->status === 'Approved')
                                    <span class="text-success">Aprobado</span>
                                @else
                                    <span class="text-danger">Rechazado</span>
                                @endif
                            </td>
                            <td>{{ $change->created_at }}</td>
                            <td>
                                <a href="{{ route('staff.username-changes.show', ['id' => $change->id]) }}" class="form__button form__button--filled">
                                    Ver detalles
                                </a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </section>
@endsection
